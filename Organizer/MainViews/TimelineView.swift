//
//  ContentView.swift
//  Organizer
//
//  Created by Toma Minchev on 25.02.26.
//

import SwiftUI
import SwiftData


protocol TimelineEntry: Identifiable {
    var secondsFromMidnight: Int { get }
}


struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: [SortDescriptor(\Event.dueDate)]) private var events: [Event]
    @Query(sort: [SortDescriptor(\Routine.dueHour), SortDescriptor(\Routine.dueMinute)]) private var routines: [Routine]
    
    @State private var showingAddEvent = false
    @State private var showActionButtons = false
    @State private var showRoutines = true
    @State private var selectedDate = Date()
    
    private var selectedWeekday: Int { Calendar.current.component(.weekday, from: selectedDate) }
    private var filteredRoutines: [Routine] { routines.filter { $0.recurrences.contains(selectedWeekday) } }
    private var filteredEvents: [Event] { events.filter { event in Calendar.current.isDate(event.dueDate, inSameDayAs: selectedDate) } }
    
    private var timelineItems: [any TimelineEntry] {
        let items: [any TimelineEntry] = filteredEvents + filteredRoutines
        return items.sorted { lhs, rhs in
            (lhs as? Event)?.secondsFromMidnight ?? (lhs as? Routine)?.secondsFromMidnight ?? 0 <
            (rhs as? Event)?.secondsFromMidnight ?? (rhs as? Routine)?.secondsFromMidnight ?? 0
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                List {
                    ForEach(Array(timelineItems.enumerated()), id: \.offset) { _, item in
                        if let event = item as? Event {
                            EventRowView(
                                event: event,
                                showActionButtons: showActionButtons
                            )
                        }

                        if showRoutines, let routine = item as? Routine {
                            RoutineRowView(
                                routine: routine,
                                selectedWeekday: Weekday(rawValue: selectedWeekday)!,
                                showActionButtons: showActionButtons,
                                orderedWeekdays: Weekday.allCases
                            )
                        }
                    }
                }
                .navigationTitle("Timeline")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        if !showActionButtons && events.count > 0 {
                            Button("Edit") {
                                withAnimation {
                                    showActionButtons = true
                                }
                            }
                        } else if events.count > 0 {
                            Button(role: .confirm) {
                                withAnimation {
                                    showActionButtons = false
                                }
                            }
                            label: {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if !showActionButtons {
                            Button { showingAddEvent = true }
                            label: { Label("Add Event", systemImage: "plus") }
                        }
                    }
                }
                .overlay {
                    if filteredEvents.isEmpty && !showRoutines {
                        ContentUnavailableView(
                            "No Events",
                            systemImage: "list.bullet",
                            description: Text("There are no events for this date.")
                        )
                    } else if filteredEvents.isEmpty && showRoutines && filteredRoutines.isEmpty {
                        ContentUnavailableView(
                            "Nothing Scheduled",
                            systemImage: "list.bullet",
                            description: Text("There are no items for this date.")
                        )
                    }
                }
                .sheet(isPresented: $showingAddEvent) {
                    AddEventView()
                }
                .contentMargins(.top, 50)
                .task {
                    seedIfNeeded()
                }
                
                HStack {
                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .background(Capsule().fill(.regularMaterial))
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    
                    Spacer()
                    
                    Toggle(isOn: $showRoutines) {
                        Image(systemName: "repeat")
                    }
                    .toggleStyle(.button)
                    .foregroundColor(showRoutines ? .accentColor : .primary)
                    .background(Capsule().fill(Color(.secondarySystemFill)))
                    .background(Capsule().fill(.regularMaterial))
                }
                .padding(.horizontal)
                .padding(.top, 7)
                .zIndex(1)
            }
        }
    }
    
    private func seedIfNeeded() {
        if events.isEmpty {
            let calendar = Calendar.current
            let today = Date()
            
            let dates = [
                calendar.date(byAdding: .day, value: -1, to: today)!,
                today,
                calendar.date(byAdding: .day, value: 1, to: today)!
            ]
            
            for date in dates {
                for _ in 0..<4 {
                    let event = Event(
                        name: "Sample Event",
                        details: "Seeded event",
                        dueDate: date,
                        isCompleted: false,
                        recurrenceValue: 1,
                        recurrenceUnit: .day
                    )
                    
                    modelContext.insert(event)
                }
            }
            
            try? modelContext.save()
        }
    }
}
