//
//  EditRoutineView.swift
//  Organizer
//

import SwiftUI
import SwiftData

struct DraftRoutine: Equatable {
    var name: String
    var details: String
    var dueHour: Int
    var dueMinute: Int
    var recurrences: [Int]
    var notify: Bool
    var notifyOffsetValue: Int
    var notifyOffsetUnit: RecurrenceUnit
}

struct EditRoutineView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var routine: Routine
    
    @State private var showDeleteConfirmation = false
    @State private var draft: DraftRoutine
    @State private var snapshot: DraftRoutine
    
    let orderedWeekdays: [Weekday]
    let selectedWeekday: Weekday

    private var isDirty: Bool { draft != snapshot }
    private var isNameValid: Bool { !draft.name.trimmingCharacters(in: .whitespaces).isEmpty }

    init(routine: Routine, orderedWeekdays: [Weekday], selectedWeekday: Weekday) {
        self.routine = routine
        self.orderedWeekdays = orderedWeekdays
        self.selectedWeekday = selectedWeekday

        let snap = DraftRoutine(
            name: routine.name,
            details: routine.details,
            dueHour: routine.dueHour,
            dueMinute: routine.dueMinute,
            recurrences: routine.recurrences,
            notify: routine.notify,
            notifyOffsetValue: routine.notifyOffsetValue,
            notifyOffsetUnit: routine.notifyOffsetUnit,
        )

        _draft = State(initialValue: snap)
        self.snapshot = snap
    }

    private var completedBinding: Binding<Bool> {
        Binding(
            get: { routine.completions.contains(selectedWeekday.id) },
            set: { newValue in
                if newValue {
                    if !routine.completions.contains(selectedWeekday.id) {
                        routine.completions.append(selectedWeekday.id)
                        routine.deleteSingleNotification(weekday: selectedWeekday.id)
                    }
                } else {
                    routine.completions.removeAll { $0 == selectedWeekday.id }
                    routine.scheduleNotification()
                }
            }
        )
    }

    private var dueBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(bySettingHour: draft.dueHour, minute: draft.dueMinute, second: 0, of: Date() ) ?? Date()
            },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                draft.dueHour = comps.hour ?? 0
                draft.dueMinute = comps.minute ?? 0
            }
        )
    }

    
    var body: some View {
        Form {
            TextField("Name", text: $draft.name)
                .bold()
                .padding(.top, 6)
                .padding(.horizontal, 6)
            
            ZStack(alignment: .topLeading) {
                if draft.details.isEmpty {
                    Text("Details")
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                        .padding(.horizontal, 6)
                        .bold()
                }
                
                TextEditor(text: $draft.details)
                    .frame(minHeight: 120)
                    .frame(maxHeight: 300)
            }
            
            DatePicker("Complete By", selection: dueBinding, displayedComponents: .hourAndMinute)
            Toggle("Completed", isOn: completedBinding)
                .sensoryFeedback(.impact(weight: .medium), trigger: routine.completions.contains(selectedWeekday.id))
            
            Section("Notify") {
                Toggle("Send notification", isOn: Binding(
                    get: { draft.notify },
                    set: { newValue in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            draft.notify = newValue
                        }
                    }
                ))
                .sensoryFeedback(.impact(weight: .medium), trigger: draft.notify)
                
                if draft.notify {
                    HStack {
                        Text("Early reminder")
                        Spacer()
                        Menu {
                            Button("0") { draft.notifyOffsetValue = 0 }
                            ForEach(RecurrenceUnit.recurrenceRange(recurrenceUnit: draft.notifyOffsetUnit), id: \.self) { value in
                                Button("\(value)") { draft.notifyOffsetValue = value }
                            }
                        } label: {
                            Text("\(draft.notifyOffsetValue)")
                                .frame(minWidth: 20)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 13)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(Color(.secondarySystemFill)))
                        }

                        Menu {
                            ForEach(RecurrenceUnit.allCases, id: \.self) { unit in
                                Button(unit.localizedLabel(value: draft.notifyOffsetValue)) {
                                    draft.notifyOffsetUnit = unit
                                }
                            }
                        } label: {
                            Text(draft.notifyOffsetUnit.localizedLabel(value: draft.notifyOffsetValue))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 13)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(Color(.secondarySystemFill)))
                        }
                    }
                }
            }

            
            Section("Repeat") {
                ForEach(orderedWeekdays) { day in
                    Button {
                        toggleDay(day.rawValue)
                    } label: {
                        HStack {
                            Text(day.localizedName)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if draft.recurrences.contains(day.rawValue) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .sensoryFeedback(.impact(weight: .medium), trigger: draft.recurrences.contains(day.rawValue))
                }
            }
        }
        .navigationTitle("Edit Routine")
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(isDirty)
        .navigationBarBackButtonHidden(isDirty)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if isDirty {
                    Button("Cancel") {
                        draft = snapshot
                    }
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                if isDirty {
                    Button {
                        if isNameValid {
                            applyChanges()
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        } else {
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                        }
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .foregroundColor(isNameValid ? .accentColor : .gray)
                } else {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .popover(isPresented: $showDeleteConfirmation) {
                        VStack(alignment: .leading, spacing: 14) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Delete Routine?")
                                .font(.headline)
                                
                                Text("This action cannot be undone.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.horizontal, 14)
                            .padding(.top, 8)
                            
                            Button {
                                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                showDeleteConfirmation = false
                                routine.deleteNotifications()
                                modelContext.delete(routine)
                                dismiss()
                            } label: {
                                Text("Delete Event")
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                            }
                            .padding(14)
                            .background(Capsule().fill(.ultraThinMaterial))
                        }
                        .padding(14)
                        .frame(width: 200)
                        .presentationCompactAdaptation(.popover)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isDirty)
    }
    
    private func toggleDay(_ day: Int) {
        if draft.recurrences.contains(day) {
            draft.recurrences.removeAll { $0 == day }
        } else {
            draft.recurrences.append(day)
        }
    }

    private func applyChanges() {
        routine.name = draft.name
        routine.details = draft.details
        routine.dueHour = draft.dueHour
        routine.dueMinute = draft.dueMinute
        routine.recurrences = draft.recurrences
        routine.notify = draft.notify
        routine.notifyOffsetUnit = draft.notifyOffsetUnit
        routine.notifyOffsetValue = draft.notifyOffsetValue

        snapshot = draft
        
        if draft.notify { routine.scheduleNotification() }
        else { routine.deleteNotifications() }
    }
}
