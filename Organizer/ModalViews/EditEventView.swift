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
