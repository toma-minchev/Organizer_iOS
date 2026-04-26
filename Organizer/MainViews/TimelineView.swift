//
//  ContentView.swift
//  Organizer
//
//  Created by Toma Minchev on 25.02.26.
//

import SwiftUI
import SwiftData


protocol TimelineEntry {
    var secondsFromMidnight: Int { get }
    var persistentModelID: PersistentIdentifier { get }
}


struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: [SortDescriptor(\Event.dueDate)]) private var events: [Event]
    @Query(sort: [SortDescriptor(\Routine.dueHour), SortDescriptor(\Routine.dueMinute)]) private var routines: [Routine]
    
    @State private var slideDirection: Edge = .trailing
    @State private var showingAddEvent = false
    @State private var showActionButtons = false
    @State private var showRoutines = true
    @State private var selectedDate = Date()
    
    private var selectedWeekday: Int { Calendar.current.component(.weekday, from: selectedDate) }
    private var filteredRoutines: [Routine] { routines.filter { $0.recurrences.contains(selectedWeekday) } }
    private var filteredEvents: [Event] { events.filter { $0.occurs(on: selectedDate) } }
    private var timelineItems: [any TimelineEntry] {
        (filteredEvents as [any TimelineEntry] + filteredRoutines as [any TimelineEntry])
        .sorted { ($0.secondsFromMidnight, $0 is Routine ? 1 : 0) < ($1.secondsFromMidnight, $1 is Routine ? 1 : 0)}
    }
    
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ZStack {
                    List {
                        ForEach(timelineItems, id: \.persistentModelID) { item in
                            if let event = item as? Event {
                                EventRowView(event: event, showActionButtons: showActionButtons, selectedDate: selectedDate)
                            }
                            
                            if showRoutines, let routine = item as? Routine {
                                RoutineRowView( routine: routine, selectedWeekday: Weekday(rawValue: selectedWeekday)!, showActionButtons: showActionButtons, orderedWeekdays: Weekday.allCases
                                )
                            }
                        }
                    }
                    .id(selectedDate)
                    .contentMargins(.top, 50)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: timelineItems.count)
                    .gesture(
                        DragGesture(minimumDistance: 50, coordinateSpace: .local)
                        .onEnded { value in
                            if value.translation.width < 0 {
                                slideDirection = .trailing
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)!
                                }
                            } else if value.translation.width > 0 {
                                slideDirection = .leading
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate)!
                                }
                            }
                        }
                    )
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
                }
                
                HStack {
                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .background(Capsule().fill(.regularMaterial))
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    
                    Spacer()
                    
                    Toggle(isOn: $showRoutines.animation(.easeInOut(duration: 0.2))) {
                        Image(systemName: "repeat")
                    }
                    .toggleStyle(.button)
                    .foregroundColor(showRoutines ? .accentColor : .primary)
                    .background(Capsule().fill(Color(.secondarySystemFill)))
                    .background(Capsule().fill(.regularMaterial))
                    .sensoryFeedback(.impact(weight: .medium), trigger: showRoutines)
                }
                .padding(.horizontal)
                .padding(.top, 7)
                .zIndex(1)
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
            .onDisappear {
                showActionButtons = false
            }
            .sheet(isPresented: $showingAddEvent) {
                AddEventView(selectedDate: selectedDate)
            }
            .task {
                seedIfNeeded()
            }
        }
    }
    
    private func seedIfNeeded() {
        guard events.isEmpty else { return }
        
        let calendar = Calendar.current
        let today = Date()
        
        let eventTemplates: [(name: String, details: String, offsetDays: Int, hour: Int, minute: Int, recurrence: (value: Int, unit: RecurrenceUnit)?)] = [
            ("Project Meeting", "Discuss sprint tasks", 0, 10, 0, nil),
            ("Lunch with Friend", "Meet at cafe", 0, 13, 30, nil),
            ("Workout", "Gym session", -1, 18, 0, (1, .day)),
            ("Check Email", "Daily inbox review", 0, 8, 0, (1, .day)),
            ("Pay Bills", "Monthly electricity and internet", 2, 12, 0, (1, .month)),
            ("Weekly Review", "Review goals and tasks", 0, 17, 30, (1, .week))
        ]
        
        for template in eventTemplates {
            guard let dueDate = calendar.date(
                byAdding: .day,
                value: template.offsetDays,
                to: today
            ) else { continue }
            
            let event = Event(
                name: template.name,
                details: template.details,
                dueDate: calendar.date(
                    bySettingHour: template.hour,
                    minute: template.minute,
                    second: 0,
                    of: dueDate
                ) ?? dueDate,
                creationDate: today,
                isCompleted: false,
                recurrenceValue: template.recurrence?.value ?? 0,
                recurrenceUnit: template.recurrence?.unit ?? .day
            )
            
            modelContext.insert(event)
            event.scheduleNotification()
        }
        
        try? modelContext.save()
    }
}
