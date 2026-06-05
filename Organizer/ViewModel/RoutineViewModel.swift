//
//  RoutineViewModel.swift
//  Organizer
//

import SwiftUI
import SwiftData
import UserNotifications


@Observable
class RoutineViewModel {

    // MARK: - UI State

    var slideDirection: Edge = .trailing
    var showActionButtons: Bool = false
    var addRoutineItem: AddRoutineContext? = nil
    var selectedWeekday: Weekday = {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return Weekday(rawValue: weekday)!
    }()

    // MARK: - Persisted State

    var lastWeekNumber: Int {
        get { UserDefaults.standard.integer(forKey: "lastWeekNumber") }
        set { UserDefaults.standard.set(newValue, forKey: "lastWeekNumber") }
    }

    // MARK: - Computed Properties

    var currentWeekNumber: Int {
        var calendar = Calendar.current
        calendar.firstWeekday = Calendar.current.firstWeekday
        return calendar.component(.weekOfYear, from: Date())
    }

    var orderedWeekdays: [Weekday] {
        let first = Calendar.current.firstWeekday
        guard let index = Weekday.allCases.firstIndex(where: { $0.rawValue == first }) else {
            return Weekday.allCases
        }
        return Array(Weekday.allCases[index...] + Weekday.allCases[..<index])
    }

    // MARK: - Filtering

    func filteredRoutines(from routines: [Routine]) -> [Routine] {
        routines.filter { $0.recurrences.contains(selectedWeekday.rawValue) }
    }

    // MARK: - Navigation

    func navigateToNextDay() {
        let current = orderedWeekdays.firstIndex(of: selectedWeekday)!
        slideDirection = .trailing
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedWeekday = orderedWeekdays[(current + 1) % orderedWeekdays.count]
        }
    }

    func navigateToPreviousDay() {
        let current = orderedWeekdays.firstIndex(of: selectedWeekday)!
        slideDirection = .leading
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedWeekday = orderedWeekdays[(current - 1 + orderedWeekdays.count) % orderedWeekdays.count]
        }
    }

    // MARK: - Business Logic

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

    func resetRoutinesIfNewWeek(routines: [Routine], modelContext: ModelContext) {
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

    func seedIfNeeded(routines: [Routine], modelContext: ModelContext) {
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
            ("Седмична ретроспекция",       "Какво мина добре, какво — не",        18,  0, true, 15, .minute, [6]),
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
