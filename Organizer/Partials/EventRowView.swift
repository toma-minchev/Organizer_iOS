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
    let selectedDate: Date
    private var isOverdue: Bool { event.dueDate < Date() && selectedDate < Date() && !event.isCompleted }
    
    private func handleCompletion() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation {
            event.isCompleted.toggle()
        }
        
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
    
    private func handleDeletion() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        event.deleteNotification()
        modelContext.delete(event)
    }

    
    var body: some View {
        NavigationLink {
            EditEventView(event: event)
        } label: {
            HStack {
                if showActionButtons {
                    Button {
                        handleCompletion()
                    } label: {
                        Image(systemName: event.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                    }
                    .sensoryFeedback(.impact(weight: .medium), trigger: event.isCompleted)
                    .sensoryFeedback(.impact(weight: .light), trigger: !event.isCompleted)
                    .foregroundColor(event.isCompleted ? .green : .secondary)
                    .buttonStyle(.borderless)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(event.dueDate.formatted(.dateTime.hour().minute())) • \(event.recurrenceUnit.recurrenceDescription(recurrenceUnit: event.recurrenceUnit, recurrenceValue: event.recurrenceValue))")
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
                        handleDeletion()
                    } label: {
                        Image(systemName: "trash")
                        .font(.system(size: 22))
                    }
                    .sensoryFeedback(.impact(weight: .medium), trigger: true)
                    .foregroundColor(.red)
                    .buttonStyle(.borderless)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: event.isCompleted)
        .animation(.easeInOut(duration: 0.2), value: showActionButtons)
        .contextMenu {
            Button {
                handleCompletion()
            } label: {
                Label(event.isCompleted ? "Undo" : "Done", systemImage: "checkmark")
            }
            
            Button(role: .destructive) {
                handleDeletion()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        } preview: {
            NavigationStack {
                EditEventView(event: event)
            }
        }
    }
}

