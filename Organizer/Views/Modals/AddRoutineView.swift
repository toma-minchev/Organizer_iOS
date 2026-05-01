//
//  AddRoutineView.swift
//  Organizer
//
//  Created by Toma Minchev on 2.03.26.
//

import SwiftUI
import SwiftData


struct AddRoutineView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var details = ""
    @State private var dueHour: Int = 9
    @State private var dueMinute: Int = 0
    @State private var notify: Bool = false
    @State private var notifyOffsetValue: Int = 1
    @State private var notifyOffsetUnit: RecurrenceUnit = .hour
    @State private var selectedDays: Set<Int> = []
    
    let orderedWeekdays: [Weekday]
    let duplicatedRoutine: Routine?
    
    init(orderedWeekdays: [Weekday], duplicatedRoutine: Routine?) {
        self.orderedWeekdays = orderedWeekdays
        self.duplicatedRoutine = duplicatedRoutine

        _name = State(initialValue: duplicatedRoutine?.name ?? "")
        _details = State(initialValue: duplicatedRoutine?.details ?? "")
        _dueHour = State(initialValue: duplicatedRoutine?.dueHour ?? 9)
        _dueMinute = State(initialValue: duplicatedRoutine?.dueMinute ?? 0)
        _notify = State(initialValue: duplicatedRoutine?.notify ?? false)
        _notifyOffsetValue = State(initialValue: duplicatedRoutine?.notifyOffsetValue ?? 0)
        _notifyOffsetUnit = State(initialValue: duplicatedRoutine?.notifyOffsetUnit ?? .minute)
        _selectedDays = State(initialValue: Set(duplicatedRoutine?.recurrences ?? []))
    }
    
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                .bold()
                .padding(.top, 6)
                .padding(.horizontal, 6)
                
                ZStack(alignment: .topLeading) {
                    if details.isEmpty {
                        Text("Details")
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                        .padding(.horizontal, 6)
                        .fontWeight(.semibold)
                    }

                    TextEditor(text: $details)
                    .frame(minHeight: 120)
                    .frame(maxHeight: 300)
                }
                
                DatePicker(
                    "Complete By",
                    selection: Binding<Date>(
                        get: {
                            Calendar.current.date(
                                bySettingHour: dueHour,
                                minute: dueMinute,
                                second: 0,
                                of: Date()
                            ) ?? Date()
                        },
                        set: { newDate in
                            let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                            dueHour = comps.hour ?? 0
                            dueMinute = comps.minute ?? 0
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                
                Section("Notify") {
                    Toggle("Send notification", isOn: Binding(
                        get: { return notify },
                        set: { newValue in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                notify = newValue
                            }
                        }
                    ))
                    .sensoryFeedback(.impact(weight: .medium), trigger: notify)

                    
                    if notify {
                        HStack {
                            Text("Early reminder")
                            Spacer()
                            Menu {
                                Button("0") { notifyOffsetValue = 0 }
                                ForEach(RecurrenceUnit.recurrenceRange(recurrenceUnit: notifyOffsetUnit), id: \.self) { value in
                                    Button("\(value)") { notifyOffsetValue = value }
                                }
                            } label: {
                                Text("\(notifyOffsetValue)")
                                    .frame(minWidth: 20)
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 13)
                                    .padding(.vertical, 8)
                                    .background(Capsule().fill(Color(.secondarySystemFill)))
                            }

                            Menu {
                                ForEach(RecurrenceUnit.allCases, id: \.self) { unit in
                                    Button(unit.localizedLabel(value: notifyOffsetValue)) {
                                        notifyOffsetUnit = unit
                                    }
                                }
                            } label: {
                                Text(notifyOffsetUnit.localizedLabel(value: notifyOffsetValue))
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
                                if selectedDays.contains(day.rawValue) {
                                    Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .sensoryFeedback(.impact(weight: .medium), trigger: selectedDays.contains(day.rawValue))
                    }
                }
            }
            .navigationTitle("New Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    let isValid = !name.trimmingCharacters(in: .whitespaces).isEmpty && !selectedDays.isEmpty
                    Button {
                        if isValid {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            saveRoutine()
                            dismiss()
                        } else {
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                        }
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .foregroundColor(isValid ? .accentColor : .gray)
                }
            }
        }
    }
    
    private func toggleDay(_ day: Int) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
    
    private func saveRoutine() {
        let newRoutine = Routine(
            name: name,
            details: details,
            dueHour: dueHour,
            dueMinute: dueMinute,
            completions: [],
            recurrences: Array(selectedDays).sorted(),
            notify: notify,
            notifyOffsetValue: notifyOffsetValue,
            notifyOffsetUnit: notifyOffsetUnit
        )
        
        modelContext.insert(newRoutine)
        try? modelContext.save()
        
        newRoutine.scheduleNotification()
    }
}
