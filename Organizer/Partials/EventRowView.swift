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
    
    @State private var showDeleteConfirmation = false
    
    let event: Event
    let showRoutines: Bool
    let showActionButtons: Bool
    let selectedDate: Date
    let selectedTab: Int
    let onDuplicate: (Event) -> Void
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
        showDeleteConfirmation = false
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
                        Image(systemName: event.isCompleted ? "checkmark.circle.fill" : "checkmark.circle")
                        .font(.system(size: 22))
                    }
                    .padding(.trailing, 6)
                    .sensoryFeedback(.impact(weight: .medium), trigger: event.isCompleted)
                    .sensoryFeedback(.impact(weight: .light), trigger: !event.isCompleted)
                    .foregroundColor(event.isCompleted ? .green : .secondary)
                    .buttonStyle(.borderless)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 8) {
                        if selectedTab == 0 {
                            if showRoutines {
                                Image(systemName: "list.bullet")
                                .font(.subheadline)
                                .foregroundStyle(event.priority.color)
                                .padding(.top, 2)
                            } else {
                                Image(systemName: "circlebadge.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(event.priority.color)
                                .padding(.top, 5)
                            }
                        }

                        Text("\(event.dueDate.formatted(.dateTime.hour().minute()))")
                        .font(.subheadline)
                        .foregroundStyle(isOverdue ? Color(.red) : .secondary)

                        Text("\(event.recurrenceUnit.recurrenceDescription(recurrenceUnit: event.recurrenceUnit, recurrenceValue: event.recurrenceValue))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    
                    Text(event.name)
                    .lineLimit(1)
                    .bold()
                    .foregroundColor(event.isCompleted ? .secondary : .primary)
                    .strikethrough(event.isCompleted)
                    
                    if !event.isCompleted && !event.details.isEmpty {
                        Text(event.details)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .transition(.scale(scale: 0.95).combined(with: .opacity))
                    }
                }
                
                Spacer()
                
                if showActionButtons {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                        .font(.system(size: 22))
                    }
                    .sensoryFeedback(.impact(weight: .medium), trigger: true)
                    .foregroundColor(.red)
                    .buttonStyle(.borderless)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .popover(isPresented: $showDeleteConfirmation) {
                        VStack(alignment: .leading, spacing: 14) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Delete Event?")
                                .font(.headline)
                                
                                Text("This action cannot be undone.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.horizontal, 14)
                            .padding(.top, 8)
                            
                            Button {
                                handleDeletion()
                            } label: {
                                Text("Delete Event")
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                            }
                            .padding(14)
                            .background(Capsule().fill(.ultraThinMaterial))
                        }
                        .padding(14)
                        .frame(width: 200)
                        .presentationCompactAdaptation(.popover)
                    }
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
            
            Button {
                onDuplicate(event)
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            
            Menu {
                Section("This action cannot be undone.") {
                    Button(role: .destructive) {
                        handleDeletion()
                    } label: {
                        Label("Delete Event", systemImage: "trash")
                    }
                }
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
