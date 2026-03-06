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
    @State private var selectedDays: Set<Int> = []
    
    let orderedWeekdays: [Weekday]
    
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
                
                Section("Repeat") {
                    ForEach(orderedWeekdays) { day in
                        Button {
                            toggleDay(day.rawValue)
                        } label: {
                            HStack {
                                Text(String(describing: day).capitalized)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                if selectedDays.contains(day.rawValue) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
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
                    Button(role: .confirm) {
                        saveRoutine()
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .disabled(
                        name.trimmingCharacters(in: .whitespaces).isEmpty ||
                        selectedDays.isEmpty
                    )
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
            recurrences: Array(selectedDays).sorted()
        )
        
        modelContext.insert(newRoutine)
        try? modelContext.save()
    }
}

