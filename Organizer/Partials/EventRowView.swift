//
//  EventRowView.swift
//  Organizer
//
//  Created by Toma Minchev on 6.03.26.
//
import SwiftUI
import SwiftData


struct EventRowView: View {
    @Environment(\.modelContext) private var modelContext
    
    let event: Event
    let showActionButtons: Bool
    let pickedDate: Date
    private var isOverdue: Bool { event.dueDate < Date() && pickedDate < Date() && !event.isCompleted }

    
    var body: some View {
        NavigationLink {
            EditEventView(event: event)
        } label: {
            HStack {
                if showActionButtons {
                    Button {
                        withAnimation {
                            event.isCompleted.toggle()
                        }
                        if event.isCompleted && event.recurrenceValue > 0 {
                            event.addToDueDate()
                        }
                    } label: {
                        Image(systemName: event.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                    }
                    .foregroundColor(event.isCompleted ? .green : .secondary)
                    .buttonStyle(.borderless)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(event.dueDate.formatted(.dateTime.hour().minute())) • \(event.recurrenceDescription)")
                    .font(.subheadline)
                    .foregroundStyle(isOverdue ? Color(.red) : .secondary)
                    
                    Text(event.name)
                    .lineLimit(1)
                    .bold()
                    .foregroundColor(event.isCompleted ? .secondary : .primary)
                    .strikethrough(event.isCompleted)
                    
                    if !event.isCompleted && !event.details.isEmpty {
                        Text(event.details)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if showActionButtons {
                    Button(role: .destructive) {
                        modelContext.delete(event)
                    } label: {
                        Image(systemName: "trash")
                        .font(.system(size: 22))
                    }
                    .foregroundColor(.red)
                    .buttonStyle(.borderless)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: showActionButtons)
        }
        .swipeActions(edge: .trailing) {
            Button {
                withAnimation {
                    event.isCompleted.toggle()
                }
                if event.isCompleted && event.recurrenceValue > 0 {
                    event.addToDueDate()
                }
            } label: {
                Label(event.isCompleted ? "Undo" : "Done", systemImage: "checkmark")
            }
            .tint(event.isCompleted ? .secondary : .blue)
            
            Button(role: .destructive) {
                modelContext.delete(event)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
