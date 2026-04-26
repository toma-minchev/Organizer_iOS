//
//  EditEventView.swift
//  Organizer
//
//  Created by Toma Minchev on 26.02.26.
//

import SwiftUI
import SwiftData


struct EditEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var event: Event
    
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $event.name)
                .bold(true)
                .padding(.top, 6)
                .padding(.horizontal, 6)
                
                ZStack(alignment: .topLeading) {
                    if event.details.isEmpty {
                        Text("Details")
                        .foregroundColor(.secondary)
                        .padding(.top, 6)
                        .padding(.horizontal, 6)
                        .bold()
                    }

                    TextEditor(text: $event.details)
                    .frame(minHeight: 120)
                    .frame(maxHeight: 300)
                }
                
                DatePicker("Due Date", selection: $event.dueDate)
                Toggle("Completed", isOn: $event.isCompleted)
                .sensoryFeedback(.impact(weight: .medium), trigger: event.isCompleted)
                
                Section("Repeat") {
                    Toggle("Repeat", isOn: Binding(
                        get: { event.recurrenceValue > 0 },
                        set: { newValue in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                event.recurrenceValue = newValue ? 1 : 0
                            }
                        }                    ))
                    .sensoryFeedback(.impact(weight: .medium), trigger: event.recurrenceValue > 0)


                    if event.recurrenceValue > 0 {
                        HStack {
                            Text("Every")
                            Spacer()
                            Menu {
                                ForEach(RecurrenceUnit.recurrenceRange(recurrenceUnit: event.recurrenceUnit), id: \.self) { value in
                                    Button("\(value)") { event.recurrenceValue = value }
                                }
                            } label: {
                                Text("\(event.recurrenceValue)")
                                .frame(minWidth: 20)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 13)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(Color(.secondarySystemFill)))
                            }

                            Menu {
                                ForEach(RecurrenceUnit.allCases, id: \.self) { unit in
                                    Button(unit.localizedLabel(value: event.recurrenceValue)) { event.recurrenceUnit = unit }
                                }
                            } label: {
                                Text(event.recurrenceUnit.localizedLabel(value: event.recurrenceValue))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 13)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(Color(.secondarySystemFill)))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive) {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        event.deleteNotification()
                        modelContext.delete(event)
                        dismiss()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .onChange(of: event.recurrenceUnit) {
                event.recurrenceValue = min(event.recurrenceValue, RecurrenceUnit.recurrenceRange(recurrenceUnit: event.recurrenceUnit).upperBound)
                event.scheduleNotification()
            }
            .onChange(of: event.recurrenceValue) {
                event.scheduleNotification()
            }
            .onChange(of: event.dueDate) {
                event.scheduleNotification()
            }
            .onChange(of: event.isCompleted) {
                if event.isCompleted {
                    if event.recurrenceValue > 0 {
                        event.addToDueDate()
                        event.scheduleNotification()
                    } else {
                        event.deleteNotification()
                    }
                } else {
                    event.scheduleNotification()
                }
            }
        }
    }
}
