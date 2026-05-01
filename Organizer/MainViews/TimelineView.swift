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

enum TimePeriod: String, CaseIterable {
    case morning
    case midday
    case afternoon
    case evening
    case night

    var title: String {
        switch self {
        case .morning: return String(localized: "Morning")
        case .midday: return String(localized: "Midday")
        case .afternoon: return String(localized: "Afternoon")
        case .evening: return String(localized: "Evening")
        case .night: return String(localized: "Night")
        }
    }

    var range: Range<Int> {
        switch self {
        case .morning: return 0 ..<  9 * 3600
        case .midday: return 9*3600 ..<  12 * 3600
        case .afternoon: return 12*3600 ..<  17 * 3600
        case .evening: return 17*3600 ..<  20 * 3600
        case .night: return 20*3600 ..< 24 * 3600
        }
    }
}

struct AddEventContext: Identifiable {
    let id = UUID()
    let duplicatedEvent: Event?
}

struct AddRoutineContext: Identifiable {
    let id = UUID()
    let duplicatedRoutine: Routine?
}


struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: [SortDescriptor(\Event.dueDate)]) private var events: [Event]
    @Query(sort: [SortDescriptor(\Routine.dueHour), SortDescriptor(\Routine.dueMinute)]) private var routines: [Routine]
    
    @State private var slideDirection: Edge = .trailing
    @State private var showDatePicker = false
    @State private var showActionButtons = false
    @State private var selectedDate = Date()
    @State private var collapsedGroups: Set<String> = []
    @State private var addEventItem: AddEventContext? = nil
    @State private var addRoutineItem: AddRoutineContext? = nil
    
    @AppStorage("sortByPriority") private var sortByPriority: Bool = false
    @AppStorage("showPeriods") private var showPeriods: Bool = true
    @AppStorage("showRoutines") private var showRoutines = true
    
    let selectedTab: Int
    
    var orderedWeekdays: [Weekday] { Weekday.allCases }
    private var selectedWeekday: Int { Calendar.current.component(.weekday, from: selectedDate) }
    private var filteredRoutines: [Routine] { routines.filter { $0.recurrences.contains(selectedWeekday) } }
    private var filteredEvents: [Event] { events.filter { $0.occurs(on: selectedDate) } }
    private var timelineItems: [any TimelineEntry] {
        let combined: [any TimelineEntry] = filteredEvents + filteredRoutines
        return combined.sorted { a, b in
            if a.secondsFromMidnight != b.secondsFromMidnight {
                return a.secondsFromMidnight < b.secondsFromMidnight
            }
            return (a is Routine ? 1 : 0) < (b is Routine ? 1 : 0)
        }
    }
    
    private var groupedTimelineItems: [(name: String, items: [any TimelineEntry])] {
        TimePeriod.allCases.compactMap { period -> (name: String, items: [any TimelineEntry])? in
            let items: [any TimelineEntry] = timelineItems.filter { period.range.contains($0.secondsFromMidnight) }
            guard !items.isEmpty else { return nil }
            return (period.title, items)
        }
    }

    private var groupedByPriority: [(name: String, items: [any TimelineEntry])] {
        Priority.allCases.reversed().compactMap { priority -> (name: String, items: [any TimelineEntry])? in
            let items: [any TimelineEntry] = timelineItems.filter { ($0 as? Event)?.priority == priority }
            guard !items.isEmpty else { return nil }
            return (priority.title, items)
        }
    }

    private var activeGroups: [(name: String, items: [any TimelineEntry])] {
        sortByPriority ? groupedByPriority : groupedTimelineItems
    }
    
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ZStack {
                    List {
                        if showPeriods {
                            ForEach(activeGroups, id: \.name) { group in
                                Section {
                                    if !collapsedGroups.contains(group.name) {
                                        ForEach(group.items, id: \.persistentModelID) {
                                            rowView(for: $0)
                                        }
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                    }
                                } header: {
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            if collapsedGroups.contains(group.name) {
                                                collapsedGroups.remove(group.name)
                                            } else {
                                                collapsedGroups.insert(group.name)
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text(group.name)
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                            .rotationEffect(collapsedGroups.contains(group.name) ? .degrees(-90) : .degrees(0))
                                            .animation(.easeInOut(duration: 0.25), value: collapsedGroups)
                                        }
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        if !showPeriods {
                            ForEach(timelineItems, id: \.persistentModelID) {
                                rowView(for: $0)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .id(selectedDate)
                    .contentMargins(.top, 50)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: showRoutines)
                    .animation(.easeInOut(duration: 0.4), value: showPeriods)
                    .animation(.easeInOut(duration: 0.2), value: selectedDate)
                    .gesture(DragGesture(minimumDistance: 50, coordinateSpace: .local)
                        .onEnded { value in
                            let horizontalAmount = value.translation.width
                            let verticalAmount = value.translation.height
                            if abs(horizontalAmount) > abs(verticalAmount) {
                                slideDirection = horizontalAmount < 0 ? .trailing : .leading
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedDate = Calendar.current.date(byAdding: .day, value: horizontalAmount < 0 ? 1 : -1, to: selectedDate)!
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
                    HStack(spacing: 8) {
                        Button {
                            showDatePicker = true
                        } label: {
                            Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                                .foregroundColor(.primary)
                                .frame(maxHeight: .infinity)
                                .font(.system(size: 14))
                                .fontWeight(.medium)
                                .padding(.horizontal, 10)
                                .background(Capsule().fill(Color("CustomGray")))
                        }
                        .frame(maxHeight: 26)
                        .popover(isPresented: $showDatePicker) {
                            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .frame(width: 320)
                            .padding(.horizontal, 10)
                            .presentationCompactAdaptation(.popover)
                        }
                        
                        Spacer()
                        
                        if showPeriods {
                            Button {
                                sortByPriority.toggle()
                            } label: {
                                Image(systemName: "flag")
                                    .foregroundColor(sortByPriority ? .white : .primary)
                                    .frame(width: 50)
                                    .frame(maxHeight: 26)
                                    .background(Capsule().fill(sortByPriority ? Color.accentColor : Color("CustomGray")))
                            }
                            .sensoryFeedback(.impact(weight: .medium), trigger: sortByPriority)
                        }

                        Button {
                            showPeriods.toggle()
                        } label: {
                            Image(systemName: "list.bullet.indent")
                                .foregroundColor(showPeriods ? .white : .primary)
                                .frame(width: 50)
                                .frame(maxHeight: 26)
                                .background(Capsule().fill(showPeriods ? Color.accentColor : Color("CustomGray")))
                        }
                        .sensoryFeedback(.impact(weight: .medium), trigger: showPeriods)

                        Button {
                            showRoutines.toggle()
                        } label: {
                            Image(systemName: "repeat")
                                .foregroundColor(showRoutines ? .white : .primary)
                                .frame(width: 50)
                                .frame(maxHeight: 26)
                                .background(Capsule().fill(showRoutines ? Color.accentColor : Color("CustomGray")))
                        }
                        .sensoryFeedback(.impact(weight: .medium), trigger: showRoutines)
                    }
                    .padding(3)
                }
                .background(Capsule().fill(Color(.secondarySystemFill)))
                .background(Capsule().fill(.ultraThinMaterial))
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
                        Button { addEventItem = AddEventContext(duplicatedEvent: nil) }
                        label: { Label("Add Event", systemImage: "plus") }
                    }
                }
            }
            .onDisappear {
                showActionButtons = false
            }
            .sheet(item: $addEventItem) { context in
                AddEventView(selectedDate: selectedDate, duplicatedEvent: context.duplicatedEvent)
            }
            .sheet(item: $addRoutineItem) { context in
                AddRoutineView(orderedWeekdays: orderedWeekdays, duplicatedRoutine: context.duplicatedRoutine )
            }
            .task {
                seedIfNeeded()
            }
            .onChange(of: showRoutines) {
                sortByPriority = showRoutines ? false : sortByPriority
            }
            .onChange(of: sortByPriority) {
                showRoutines = sortByPriority ? false : showRoutines
            }
            .onChange(of: showPeriods) {
                sortByPriority = showPeriods ? false : sortByPriority
            }
        }
    }
    
    @ViewBuilder
    private func rowView(for item: any TimelineEntry) -> some View {
        if let event = item as? Event {
            EventRowView(event: event, showRoutines: showRoutines, showActionButtons: showActionButtons, selectedDate: selectedDate, selectedTab: selectedTab, onDuplicate: { event in
                addEventItem = AddEventContext(duplicatedEvent: event)
            })
        }
        if showRoutines, let routine = item as? Routine {
            RoutineRowView(routine: routine, selectedWeekday: Weekday(rawValue: selectedWeekday)!, showActionButtons: showActionButtons, orderedWeekdays: orderedWeekdays, selectedTab: selectedTab, onDuplicate: { routine in
                addRoutineItem = AddRoutineContext(duplicatedRoutine: routine)
            })
        }
    }
    
    // Create sample data for testing
    private func seedIfNeeded() {
        guard events.isEmpty else { return }
        
        let calendar = Calendar.current
        let today = Date()
        
        let eventTemplates: [(
            name: String, details: String, offsetDays: Int, hour: Int, minute: Int,
            priority: Priority, isCompleted: Bool,
            notify: Bool, notifyOffsetValue: Int, notifyOffsetUnit: RecurrenceUnit,
            recurrenceValue: Int, recurrenceUnit: RecurrenceUnit
        )] = [
            ("Скръм дейли",       "Синхрон с екипа в Meet",              0,  9, 30, .medium, false, true,  10, .minute, 1, .day),
            ("Код ревю",          "Прегледай PR-ите преди merge",         1, 11,  0, .high,   false, true,  15, .minute, 0, .day),
            ("Среща с клиента",   "Демо на новите функции пред клиента",  3, 14,  0, .high,   false, true,  30, .minute, 0, .day),
            ("Плащане на сметки", "Ток, интернет и абонаменти",           5, 12,  0, .medium, false, true,   1, .day,    1, .month),
            ("Спринт планиране",  "Планиране на задачите за спринта",     0, 10,  0, .high,   false, true,  20, .minute, 2, .week),
            ("Бек-ъп на проекти", "Качи локалните репота в облака",       1, 20,  0, .low,    false, true,   1, .hour,   1, .week),
            ("Актуализирай CV",   "Добави последните проекти и умения",  14,  9,  0, .low,    false, true,   1, .day,    1, .year),
            ("Прегледай задачи",  "Провери Jira и затвори стари тикети",  0, 17, 30, .medium, false, true,  15, .minute, 1, .day),
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
                priority: template.priority,
                isCompleted: template.isCompleted,
                notify: template.notify,
                notifyOffsetValue: template.notifyOffsetValue,
                notifyOffsetUnit: template.notifyOffsetUnit,
                recurrenceValue: template.recurrenceValue,
                recurrenceUnit: template.recurrenceUnit
            )
            
            modelContext.insert(event)
            event.scheduleNotification()
        }
        
        try? modelContext.save()
    }
}
