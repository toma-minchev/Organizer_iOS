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
}

struct EditRoutineView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var routine: Routine
    let orderedWeekdays: [Weekday]
    let selectedWeekday: Weekday

    @State private var draft: DraftRoutine
    private let snapshot: DraftRoutine

    init(routine: Routine, orderedWeekdays: [Weekday], selectedWeekday: Weekday) {
        self.routine = routine
        self.orderedWeekdays = orderedWeekdays
        self.selectedWeekday = selectedWeekday

        let snap = DraftRoutine(
            name: routine.name,
            details: routine.details,
            dueHour: routine.dueHour,
            dueMinute: routine.dueMinute,
            recurrences: routine.recurrences
        )

        _draft = State(initialValue: snap)
        self.snapshot = snap
    }

    @State private var isDirty: Bool = false

    private var isNameValid: Bool {
        !draft.name.trimmingCharacters(in: .whitespaces).isEmpty
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

        routine.scheduleNotification()
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
                        dismiss()
                    }
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                if isDirty {
                    Button {
                        if isNameValid {
                            applyChanges()
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            dismiss()
                        } else {
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                        }
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .foregroundColor(isNameValid ? .accentColor : .gray)
                } else {
                    Button(role: .destructive) {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        routine.deleteNotifications()
                        modelContext.delete(routine)
                        dismiss()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .onChange(of: draft) {
            withAnimation(.easeInOut(duration: 0.2)) {
                isDirty = draft != snapshot
            }
        }
    }
}
