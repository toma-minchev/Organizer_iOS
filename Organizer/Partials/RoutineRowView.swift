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
    
    let routine: Routine
    let selectedWeekday: Weekday
    let showActionButtons: Bool
    let orderedWeekdays: [Weekday]
    
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
                        Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22))
                    }
                    .sensoryFeedback(.impact(weight: .medium), trigger: isCompleted)
                    .sensoryFeedback(.impact(weight: .light), trigger: !isCompleted)
                    .foregroundColor(isCompleted ? .green : .secondary)
                    .buttonStyle(.borderless)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(String(format: "%02d:%02d", routine.dueHour, routine.dueMinute)) • \(routine.recurrenceDescription)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(routine.name)
                        .lineLimit(1)
                        .bold()
                        .foregroundColor(isCompleted ? .secondary : .primary)
                        .strikethrough(isCompleted)
                    
                    if !isCompleted && !routine.details.isEmpty {
                        Text(routine.details)
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
        .animation(.easeInOut(duration: 0.2), value: isCompleted)
        .animation(.easeInOut(duration: 0.2), value: showActionButtons)
        .contextMenu {
            Button {
                handleCompletion()
            } label: {
                Label(isCompleted ? "Undo" : "Done", systemImage: "checkmark")
            }
            
            Button(role: .destructive) {
                handleDeletion()
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
