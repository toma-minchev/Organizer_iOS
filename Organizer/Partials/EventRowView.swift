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
    
    var body: some View {
        NavigationLink {
            EditEventView(event: event)
        } label: {
            HStack {
                if showActionButtons {
                    Button {
                        event.isCompleted.toggle()
                    } label: {
                        Image(systemName: event.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22))
                    }
                    .foregroundColor(event.isCompleted ? .green : .secondary)
                    .buttonStyle(.borderless)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(event.dueDate.formatted(.dateTime.hour().minute())) • \(recurrenceText(for: event.recurrence))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
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
        }
        .swipeActions(edge: .trailing) {
            Button {
                withAnimation {
                    event.isCompleted.toggle()
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
    
    private func recurrenceText(for hours: Int) -> String {
        switch hours {
        case 0: return "No repeat"
        case 1: return "Every hour"
        case 2: return "Every 2 hours"
        case 3: return "Every 3 hours"
        case 6: return "Every 6 hours"
        case 12: return "Every 12 hours"
        case 24: return "Every day"
        case 48: return "Every 2 days"
        case 72: return "Every 3 days"
        case 168: return "Every week"
        case 336: return "Every 2 weeks"
        case 504: return "Every 3 weeks"
        case 720: return "Every month"
        default: return "Custom"
        }
    }
}
