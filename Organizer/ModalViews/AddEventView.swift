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
    @State private var recurrenceValue: Int = 0
    @State private var recurrenceUnit: RecurrenceUnit = .day
    
    let selectedDate: Date
    
    init(selectedDate: Date) {
        self.selectedDate = selectedDate
        _dueDate = State(initialValue: selectedDate)
    }
    
    private func saveEvent() {
        let newEvent = Event(
            name: name,
            details: details,
            dueDate: dueDate,
            creationDate: Date(),
            isCompleted: false,
            recurrenceValue: recurrenceValue,
            recurrenceUnit: recurrenceValue == 0 ? .day : recurrenceUnit
        )

        modelContext.insert(newEvent)
        try? modelContext.save()
        
        newEvent.scheduleNotification()
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
                
                DatePicker(.init("Due Date"), selection: Binding<Date>(get: { self.dueDate }, set: { self.dueDate = $0 }))
                
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
