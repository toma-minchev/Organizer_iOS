//
//  RoutineView.swift
//  Organizer
//
//  Created by Toma Minchev on 27.02.26.
//

import SwiftUI
import SwiftData


enum Weekday: Int, CaseIterable, Identifiable {
    case sunday = 1
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday

    var id: Int { rawValue }
    var shortLetter: String {
        Calendar.current.shortWeekdaySymbols[self.rawValue - 1].capitalized
    }
    
    var localizedName: String {
        Calendar.current.weekdaySymbols[self.rawValue - 1].capitalized
    }
}

struct RoutineView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: [SortDescriptor(\Routine.dueHour), SortDescriptor(\Routine.dueMinute)])
    private var routines: [Routine]
    
    @State private var slideDirection: Edge = .trailing
    @State private var showActionButtons = false
    @State private var addRoutineItem: AddRoutineContext? = nil
    @State private var selectedWeekday: Weekday = {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return Weekday(rawValue: weekday)!
    }()
    
    @AppStorage("lastWeekNumber") private var lastWeekNumber: Int = 0
    private var currentWeekNumber: Int {
        var calendar = Calendar.current
        calendar.firstWeekday = Calendar.current.firstWeekday
        return calendar.component(.weekOfYear, from: Date())
    }
    
    let selectedTab: Int
    
    var filteredRoutines: [Routine] { routines.filter { $0.recurrences.contains(selectedWeekday.rawValue) } }
    
    private var orderedWeekdays: [Weekday] {
        let first = Calendar.current.firstWeekday
        guard let index = Weekday.allCases.firstIndex(where: { $0.rawValue == first }) else {
            return Weekday.allCases
        }
        return Array(Weekday.allCases[index...] + Weekday.allCases[..<index])
    }

    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ZStack {
                    List {
                        ForEach(filteredRoutines) { routine in
                            RoutineRowView(routine: routine, selectedWeekday: selectedWeekday, showActionButtons: showActionButtons, orderedWeekdays: orderedWeekdays, selectedTab: selectedTab,
                                onDuplicate: { routine in
                                addRoutineItem = AddRoutineContext(duplicatedRoutine: routine)
                            })
                        }
                    }
                    .id(selectedWeekday)
                    .contentMargins(.top, 50)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: filteredRoutines)
                    .gesture(DragGesture(minimumDistance: 50, coordinateSpace: .local)
                        .onEnded { value in
                            let current = orderedWeekdays.firstIndex(of: selectedWeekday)!
                            let horizontalAmount = value.translation.width
                            let verticalAmount = value.translation.height
                            if abs(horizontalAmount) > abs(verticalAmount) {
                                slideDirection = horizontalAmount < 0 ? .trailing : .leading
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedWeekday = horizontalAmount < 0 ? orderedWeekdays[(current + 1) % orderedWeekdays.count] :                                                            orderedWeekdays[(current - 1 + orderedWeekdays.count) % orderedWeekdays.count]
                                }
                            }
                        }
                    )
                    .overlay {
                        if filteredRoutines.isEmpty {
                            ContentUnavailableView(
                                "No Routine",
                                systemImage: "repeat.circle",
                                description: Text("There is no routine for this day.")
                            )
                        }
                    }
                }
                
                Picker("Day", selection: $selectedWeekday) {
                    ForEach(orderedWeekdays) { day in
                        Text(day.shortLetter).tag(day)
                    }
                }
                .pickerStyle(.segmented)
                .background(Capsule().fill(.ultraThinMaterial))
                .padding(.horizontal)
                .padding(.top, 7)
                .zIndex(1)
            }
            .toolbarBackground(.hidden)
            .navigationTitle("Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !showActionButtons && filteredRoutines.count > 0 {
                        Button("Edit") {
                            withAnimation {
                                showActionButtons = true
                            }
                        }
                    } else if filteredRoutines.count > 0 {
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
                        Button { addRoutineItem = AddRoutineContext(duplicatedRoutine: nil) }
                        label: { Label("Add Event", systemImage: "plus") }
                    }
                }
            }
            .onDisappear {
                showActionButtons = false
            }
            .sheet(item: $addRoutineItem) { context in
                AddRoutineView(orderedWeekdays: orderedWeekdays, duplicatedRoutine: context.duplicatedRoutine )
            }
            .task {
                schedulePausedNotificationsReminder()
                resetRoutinesIfNewWeek()
                seedIfNeeded()
            }
        }
    }
    
    func schedulePausedNotificationsReminder() {
        let center = UNUserNotificationCenter.current()
        
        center.removePendingNotificationRequests(withIdentifiers: ["notifications-paused-reminder"])
        
        let calendar = Calendar.current
        guard let reminderDate = calendar.date(byAdding: .weekOfYear, value: 3, to: Date()) else { return }
        
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        components.hour = 9
        components.minute = 0
        
        let content = UNMutableNotificationContent()
        content.title = "Routine notifications paused."
        content.body = "Notifications will resume when you open the app."
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "notifications-paused-reminder",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error {
                print("Failed to schedule paused notifications reminder:", error)
            }
        }
    }
    
    private func resetRoutinesIfNewWeek() {
        var calendar = Calendar.current
        calendar.firstWeekday = Calendar.current.firstWeekday
        let currentWeek = calendar.component(.weekOfYear, from: Date())
        guard currentWeek != lastWeekNumber else { return }
        
        for routine in routines {
            routine.completions = []
            routine.scheduleNotification()
        }
        
        try? modelContext.save()
        lastWeekNumber = currentWeek
    }
    
    private func seedIfNeeded() {
        guard routines.isEmpty else { return }
        
        let routineTemplates: [(
            name: String, details: String, hour: Int, minute: Int,
            notify: Bool, notifyOffsetValue: Int, notifyOffsetUnit: RecurrenceUnit,
            days: [Int]
        )] = [
            ("Провери Slack",        "Прегледай съобщенията и каналите",     8,  0, true, 5,  .minute, [2,3,4,5,6]),
            ("Сутрешно разтягане",   "15 минути стречинг пред бюрото",       7, 15, true, 5,  .minute, [2,3,4,5,6,7,1]),
            ("LeetCode задача",      "Реши поне 1 задача на ден",           21,  0, true, 10, .minute, [2,4,6]),
            ("Прочети тех статия",   "Hacker News или Medium — 20 минути",  12, 30, true, 5,  .minute, [2,3,4,5,6]),
            ("Седмично ретро",       "Какво мина добре, какво — не",        18,  0, true, 15, .minute, [6]),
            ("Спри да работиш",      "Затвори лаптопа, излез навън",        19,  0, true, 0,  .minute, [2,3,4,5,6]),
            ("Личен проект",         "Работи по side project-а",            20, 30, true, 10, .minute, [7,1]),
        ]
        
        for template in routineTemplates {
            let routine = Routine(
                name: template.name,
                details: template.details,
                dueHour: template.hour,
                dueMinute: template.minute,
                completions: [],
                recurrences: template.days,
                notify: template.notify,
                notifyOffsetValue: template.notifyOffsetValue,
                notifyOffsetUnit: template.notifyOffsetUnit,
            )
            
            modelContext.insert(routine)
            routine.scheduleNotification()
        }
        
        try? modelContext.save()
    }
}
