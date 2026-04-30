//
//  AddEventView.swift
//  Organizer
//
//  Created by Toma Minchev on 25.02.26.
//

import SwiftUI
import SwiftData


struct AddEventView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var details = ""
    @State private var dueDate = Date()
    @State private var priority: Priority = .low
    @State private var notify: Bool = false
    @State private var notifyOffsetValue: Int = 1
    @State private var notifyOffsetUnit: RecurrenceUnit = .hour
    @State private var recurrenceValue: Int = 0
    @State private var recurrenceUnit: RecurrenceUnit = .day
    
    let duplicatedEvent: Event?
    let selectedDate: Date
    
    init(selectedDate: Date, duplicatedEvent: Event?) {
        self.selectedDate = selectedDate
        _dueDate = State(initialValue: selectedDate)
        self.duplicatedEvent = duplicatedEvent

        _name = State(initialValue: duplicatedEvent?.name ?? "")
        _details = State(initialValue: duplicatedEvent?.details ?? "")
        _dueDate = State(initialValue: duplicatedEvent?.dueDate ?? selectedDate)
        _notify = State(initialValue: duplicatedEvent?.notify ?? false)
        _notifyOffsetValue = State(initialValue: duplicatedEvent?.notifyOffsetValue ?? 0)
        _notifyOffsetUnit = State(initialValue: duplicatedEvent?.notifyOffsetUnit ?? .minute)
        _recurrenceValue = State(initialValue: duplicatedEvent?.recurrenceValue ?? 0)
        _recurrenceUnit = State(initialValue: duplicatedEvent?.recurrenceUnit ?? .minute)
    }
    
    private func saveEvent() {
        let newEvent = Event(
            name: name,
            details: details,
            dueDate: dueDate,
            creationDate: Date(),
            priority: priority,
            isCompleted: false,
            notify: notify,
            notifyOffsetValue: notifyOffsetValue,
            notifyOffsetUnit: notifyOffsetUnit,
            recurrenceValue: recurrenceValue,
            recurrenceUnit: recurrenceValue == 0 ? .day : recurrenceUnit
        )

        modelContext.insert(newEvent)
        try? modelContext.save()
        
        if notify { newEvent.scheduleNotification() }
    }
    
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                .bold(true)
                .padding(.top, 6)
                .padding(.horizontal, 6)
                
                ZStack(alignment: .topLeading) {
                    if details.isEmpty {
                        Text("Details")
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                        .padding(.horizontal, 6)
                        .bold()
                    }

                    TextEditor(text: $details)
                    .frame(minHeight: 120)
                    .frame(maxHeight: 300)
                }
                
                DatePicker("Due Date", selection: $dueDate)

                HStack {
                    Text("Priority")
                    Spacer()
                    
                    Menu {
                        ForEach(Priority.allCases) { option in
                            Button(option.title) { priority = option }

                        }
                    } label: {
                        Text(priority.title)
                        .frame(minWidth: 40)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color(.secondarySystemFill)))
                    }
                }
                
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
                    Toggle("Repeat", isOn: Binding(
                        get: { recurrenceValue > 0 },
                        set: { newValue in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                recurrenceValue = newValue ? 1 : 0
                            }
                        }                    ))
                    .sensoryFeedback(.impact(weight: .medium), trigger: recurrenceValue > 0)

                    if recurrenceValue > 0 {
                        HStack {
                            Text("Every")
                            Spacer()
                            Menu {
                                ForEach(RecurrenceUnit.recurrenceRange(recurrenceUnit: recurrenceUnit), id: \.self) { value in
                                    Button("\(value)") { recurrenceValue = value }
                                }
                            } label: {
                                Text("\(recurrenceValue)")
                                .frame(minWidth: 20)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 13)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(Color(.secondarySystemFill)))
                            }

                            Menu {
                                ForEach(RecurrenceUnit.allCases, id: \.self) { unit in
                                    Button(unit.localizedLabel(value: recurrenceValue)) { recurrenceUnit = unit }
                                }
                            } label: {
                                Text(recurrenceUnit.localizedLabel(value: recurrenceValue))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 13)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(Color(.secondarySystemFill)))
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Event")
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
                    let isValid = !name.trimmingCharacters(in: .whitespaces).isEmpty
                    Button {
                        if isValid {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            saveEvent()
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
            .onChange(of: recurrenceUnit) {
                recurrenceValue = min(recurrenceValue, RecurrenceUnit.recurrenceRange(recurrenceUnit: recurrenceUnit).upperBound)
            }
        }
    }
}

