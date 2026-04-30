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
    @State private var showingAddRoutine = false
    @State private var showActionButtons = false
    @State private var routineToDuplicate: Routine? = nil
    @State private var selectedWeekday: Weekday = {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return Weekday(rawValue: weekday)!
    }()
    
    let selectedTab: Int
    
    @AppStorage("lastWeekNumber") private var lastWeekNumber: Int = 0
    private var currentWeekNumber: Int {
        var calendar = Calendar.current
        calendar.firstWeekday = Calendar.current.firstWeekday
        return calendar.component(.weekOfYear, from: Date())
    }
    
    var filteredRoutines: [Routine] { routines.filter { $0.recurrences.contains(selectedWeekday.rawValue) } }
    
    private var orderedWeekdays: [Weekday] {
        let first = Calendar.current.firstWeekday
        guard let index = Weekday.allCases.firstIndex(where: { $0.rawValue == first }) else {
            return Weekday.allCases
        }
        return Array(Weekday.allCases[index...] + Weekday.allCases[..<index])
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

    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ZStack {
                    List {
                        ForEach(filteredRoutines) { routine in
                            RoutineRowView(routine: routine, selectedWeekday: selectedWeekday, showActionButtons: showActionButtons, orderedWeekdays: orderedWeekdays, selectedTab: selectedTab,
                                onDuplicate: { routine in
                                routineToDuplicate = routine
                                showingAddRoutine = true
                            })
                        }
                    }
                    .id(selectedWeekday)
                    .contentMargins(.top, 50)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: filteredRoutines)
                    .gesture(
                        DragGesture(minimumDistance: 50, coordinateSpace: .local)
                        .onEnded { value in
                            let current = orderedWeekdays.firstIndex(of: selectedWeekday)!
                            if value.translation.width < 0 {
                                slideDirection = .trailing
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedWeekday = orderedWeekdays[(current + 1) % orderedWeekdays.count]
                                }
                            } else if value.translation.width > 0 {
                                slideDirection = .leading
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedWeekday = orderedWeekdays[(current - 1 + orderedWeekdays.count) % orderedWeekdays.count]
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
                .background(Capsule().fill(.regularMaterial))
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
                        Button { showingAddRoutine = true }
                        label: { Label("Add Event", systemImage: "plus") }
                    }
                }
            }
            .onDisappear {
                showActionButtons = false
            }
            .sheet(isPresented: $showingAddRoutine, onDismiss: {
                routineToDuplicate = nil
            }) {
                AddRoutineView(orderedWeekdays: orderedWeekdays, duplicatedRoutine: routineToDuplicate )
            }
            .task {
                schedulePausedNotificationsReminder()
                resetRoutinesIfNewWeek()
                seedIfNeeded()
            }
        }
    }
    
    private func seedIfNeeded() {
        guard routines.isEmpty else { return }
        
        let routineTemplates: [(name: String, details: String, hour: Int, minute: Int, days: [Int])] = [
            ("Morning Jog", "Jog for 30 minutes", 6, 30, [2,3,4,5,6]),
            ("Drink Water", "Drink a glass of water", 9, 0, [1,2,3,4,5,6,7]),
            ("Read Book", "Read 20 pages", 20, 0, [2,4,6]),
            ("Meditation", "10 minutes meditation", 7, 0, [1,2,3,4,5,6,7]),
            ("Weekly Call", "Call parents", 18, 0, [7])
        ]
        
        for template in routineTemplates {
            let routine = Routine(
                name: template.name,
                details: template.details,
                dueHour: template.hour,
                dueMinute: template.minute,
                completions: [],
                recurrences: template.days,
                notify: false,
                notifyOffsetValue: 0,
                notifyOffsetUnit: .minute,
            )
            
            modelContext.insert(routine)
            routine.scheduleNotification()
        }
        
        try? modelContext.save()
    }
}
