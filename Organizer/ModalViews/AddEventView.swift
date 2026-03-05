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
    @State private var recurrence: Int = 0
    
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
                Picker("Repeat", selection: $recurrence) {
                    Text("None").tag(0)
                    
                    Text("1 hour").tag(1)
                    Text("2 hours").tag(2)
                    Text("3 hours").tag(3)
                    Text("6 hours").tag(6)
                    Text("12 hours").tag(12)
                    
                    Text("1 day").tag(24)
                    Text("2 days").tag(48)
                    Text("3 days").tag(72)
                    
                    Text("1 week").tag(168)
                    Text("2 weeks").tag(336)
                    Text("3 weeks").tag(504)
                    
                    Text("1 month").tag(720)
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
                    Button(role: .confirm) {
                        saveEvent()
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func saveEvent() {
        let newEvent = Event(
            name: name,
            details: details,
            dueDate: dueDate,
            isCompleted: false,
            recurrence: recurrence
        )

        modelContext.insert(newEvent)
        try? modelContext.save()
    }
}
