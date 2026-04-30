//
//  RoutineRowView.swift
//  Organizer
//
//  Created by Toma Minchev on 6.03.26.
//
import SwiftUI
import SwiftData


struct RoutineRowView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var showDeleteConfirmation = false
    
    let routine: Routine
    let selectedWeekday: Weekday
    let showActionButtons: Bool
    let orderedWeekdays: [Weekday]
    let selectedTab: Int
    let onDuplicate: (Routine) -> Void
    
    private var dueTime: Date { Calendar.current.date(
        bySettingHour: routine.dueHour,
        minute: routine.dueMinute,
        second: 0,
        of: Date()
    ) ?? Date()}
    
    private var isCompleted: Bool { routine.completions.contains(selectedWeekday.id) }
    private var isOverdue: Bool {dueTime < Date() && !isCompleted }
    
    private func handleCompletion() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation {
            if isCompleted {
                routine.completions.removeAll { $0 == selectedWeekday.id }
                routine.deleteSingleNotification(weekday: selectedWeekday.id)
            } else {
                routine.completions.append(selectedWeekday.id)
            }
        }
    }
    
    private func handleDeletion() {
        showDeleteConfirmation = false
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        routine.deleteNotifications()
        modelContext.delete(routine)
    }

    
    var body: some View {
        NavigationLink {
            EditRoutineView(routine: routine, orderedWeekdays: orderedWeekdays, selectedWeekday: selectedWeekday)
        } label: {
            HStack {
                if showActionButtons {
                    Button {
                       handleCompletion()
                    } label: {
                        Image(systemName: isCompleted ? "checkmark.circle.fill" : "checkmark.circle")
                        .font(.system(size: 22))
                    }
                    .padding(.trailing, 6)
                    .sensoryFeedback(.impact(weight: .medium), trigger: isCompleted)
                    .sensoryFeedback(.impact(weight: .light), trigger: !isCompleted)
                    .foregroundColor(isCompleted ? .green : .secondary)
                    .buttonStyle(.borderless)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 8) {
                        if selectedTab == 0 {
                            Image(systemName: "repeat")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                        }

                        Text("\(String(format: "%02d:%02d", routine.dueHour, routine.dueMinute))")
                        .foregroundStyle(isOverdue ? Color(.red) : .secondary)
                        .font(.subheadline)

                        Text("\(routine.recurrenceDescription)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    
                    Text(routine.name)
                    .lineLimit(1)
                    .bold()
                    .foregroundColor(isCompleted ? .secondary : .primary)
                    .strikethrough(isCompleted)
                    
                    if !isCompleted && !routine.details.isEmpty {
                        Text(routine.details)
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
                                Text("Delete Routine?")
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
                                Text("Delete Routine")
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
        .animation(.easeInOut(duration: 0.2), value: isCompleted)
        .animation(.easeInOut(duration: 0.2), value: showActionButtons)
        .contextMenu {
            Button {
                handleCompletion()
            } label: {
                Label(isCompleted ? "Undo" : "Done", systemImage: "checkmark")
            }
            
            Button {
                onDuplicate(routine)
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            
            Menu {
                Section("This action cannot be undone.") {
                    Button(role: .destructive) {
                        handleDeletion()
                    } label: {
                        Label("Delete Routine", systemImage: "trash")
                    }
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        } preview: {
            NavigationStack {
                EditRoutineView(routine: routine, orderedWeekdays: orderedWeekdays, selectedWeekday: selectedWeekday)
            }
        }
    }
}

