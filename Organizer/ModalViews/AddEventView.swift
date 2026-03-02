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
            recurrence: 0
        )

        modelContext.insert(newEvent)
        try? modelContext.save()
    }
}
