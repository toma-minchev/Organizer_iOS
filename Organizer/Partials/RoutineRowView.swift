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
    
    private var completed: Bool { routine.completions.contains(selectedWeekday.id) }
    
    
    var body: some View {
        NavigationLink {
            EditRoutineView(routine: routine, orderedWeekdays: orderedWeekdays, selectedWeekday: selectedWeekday)
        } label: {
            HStack {
                if showActionButtons {
                    Button {
                        if completed {
                            routine.completions.removeAll { $0 == selectedWeekday.id }
                        } else {
                            routine.completions.append(selectedWeekday.id)
                        }
                    } label: {
                        Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22))
                    }
                    .foregroundColor(completed ? .green : .secondary)
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
                        .foregroundColor(completed ? .secondary : .primary)
                        .strikethrough(completed)
                    
                    if !completed && !routine.details.isEmpty {
                        Text(routine.details)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if showActionButtons {
                    Button(role: .destructive) {
                        modelContext.delete(routine)
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
                if completed {
                    routine.completions.removeAll { $0 == selectedWeekday.id }
                } else {
                    routine.completions.append(selectedWeekday.id)
                }
            } label: {
                Label(completed ? "Undo" : "Done", systemImage: "checkmark")
            }
            .tint(completed ? .secondary : .blue)
            
            Button(role: .destructive) {
                modelContext.delete(routine)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
