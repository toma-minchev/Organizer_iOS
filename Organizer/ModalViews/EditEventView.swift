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
                Picker("Repeat", selection: $event.recurrence) {
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
                Toggle("Completed", isOn: $event.isCompleted)
            }
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive) {
                        modelContext.delete(event)
                        dismiss()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }
}
