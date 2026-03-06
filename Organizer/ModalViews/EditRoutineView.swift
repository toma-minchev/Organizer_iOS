//
//  EditRoutineView.swift
//  Organizer
//
//  Created by Toma Minchev on 2.03.26.
//

import SwiftUI
import SwiftData

struct EditRoutineView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var routine: Routine
    let orderedWeekdays: [Weekday]
    let selectedDay: Weekday
    
    private var completedBinding: Binding<Bool> {
        Binding<Bool>(
            get: { routine.completions.contains(selectedDay.id) },
            set: { newValue in
                if newValue {
                    if !routine.completions.contains(selectedDay.id) {
                        routine.completions.append(selectedDay.id)
                    }
                } else {
                    routine.completions.removeAll { $0 == selectedDay.id }
                }
            }
        )
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $routine.name)
                    .bold(true)
                    .padding(.top, 6)
                    .padding(.horizontal, 6)
                
                ZStack(alignment: .topLeading) {
                    if routine.details.isEmpty {
                        Text("Details")
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                            .padding(.horizontal, 6)
                            .bold()
                    }

                    TextEditor(text: $routine.details)
                        .frame(minHeight: 120)
                        .frame(maxHeight: 300)
                }
                DatePicker(
                    "Complete By",
                    selection: Binding<Date>(
                        get: {
                            Calendar.current.date(
                                bySettingHour: routine.dueHour,
                                minute: routine.dueMinute,
                                second: 0,
                                of: Date()
                            ) ?? Date()
                        },
                        set: { newDate in
                            let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                            routine.dueHour = comps.hour ?? 0
                            routine.dueMinute = comps.minute ?? 0
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                Toggle("Completed", isOn: completedBinding)
                
                Section("Repeat") {
                    ForEach(orderedWeekdays) { day in
                        Button {
                            toggleDay(day.rawValue)
                        } label: {
                            HStack {
                                Text(String(describing: day).capitalized)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                if routine.recurrences.contains(day.rawValue) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive) {
                        modelContext.delete(routine)
                        dismiss()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }
    
    private func toggleDay(_ day: Int) {
        if routine.recurrences.contains(day) {
            routine.recurrences.removeAll { $0 == day }
        } else {
            routine.recurrences.append(day)
        }
    }
}

