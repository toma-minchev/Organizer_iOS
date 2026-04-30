//
//  Routine.swift
//  Organizer
//
//  Created by Toma Minchev on 25.02.26.
//

import Foundation
import SwiftData
import UserNotifications


@Model
final class Routine: TimelineEntry {
    var secondsFromMidnight: Int {
        dueHour * 3600 + dueMinute * 60
    }
    
    var name: String
    var details: String
    var dueHour: Int
    var dueMinute: Int
    var notify: Bool
    var notifyOffsetValue: Int
    var notifyOffsetUnit: RecurrenceUnit
    var completions: [Int] = []
    var recurrences: [Int] = []
    
    init(name: String, details: String, dueHour: Int, dueMinute: Int, completions: [Int], recurrences: [Int], notify: Bool, notifyOffsetValue: Int, notifyOffsetUnit: RecurrenceUnit) {
        self.name = name
        self.details = details
        self.dueHour = dueHour
        self.dueMinute = dueMinute
        self.completions = completions
        self.recurrences = recurrences
        self.notify = notify
        self.notifyOffsetValue = notifyOffsetValue
        self.notifyOffsetUnit = notifyOffsetUnit
    }
}


extension Routine {
    var recurrenceDescription: String {
        let sorted = recurrences.sorted()
        
        if sorted == [1,2,3,4,5,6,7] {
            return String(localized: "Everyday")
        }
        
        if sorted == [2,3,4,5,6] {
            return String(localized: "Workdays")
        }
        
        if sorted == [1,7] {
            return String(localized: "Weekends")
        }
        
        let symbols = Calendar.current.shortWeekdaySymbols

        return sorted
            .map { symbols[$0 - 1].capitalized }
            .joined(separator: " ")
    }
    
    func notifyOffsetLabel() -> String {
        notifyOffsetUnit.localizedLabel(value: notifyOffsetValue)
    }
    
    func scheduleNotification() {
        guard notify else {
            deleteNotifications()
            return
        }

        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current

        deleteNotifications()

        let offsetSeconds: Double
        switch notifyOffsetUnit {
        case .minute: offsetSeconds = Double(notifyOffsetValue) * 60
        case .hour:   offsetSeconds = Double(notifyOffsetValue) * 3600
        case .day:    offsetSeconds = Double(notifyOffsetValue) * 86400
        case .week:   offsetSeconds = Double(notifyOffsetValue) * 604800
        case .month:  offsetSeconds = Double(notifyOffsetValue) * 2592000
        case .year:   offsetSeconds = Double(notifyOffsetValue) * 31536000
        }

        for weekOffset in 0..<2 {
            for weekday in recurrences {
                guard let baseNextDate = calendar.nextDate(
                    after: Date(),
                    matching: DateComponents(hour: dueHour, minute: dueMinute, weekday: weekday),
                    matchingPolicy: .nextTime
                ) else { continue }

                guard let nextDate = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: baseNextDate) else { continue }

                let triggerDate = nextDate.addingTimeInterval(-offsetSeconds)
                guard triggerDate > Date() else { continue }

                let content = UNMutableNotificationContent()
                content.title = String(localized: .routineNotificationTitle(name: name))
                content.body = details.isEmpty ? String(localized: .routineNotificationText) : details
                content.sound = .default

                let identifier = "routine-\(id)-\(weekday)-\(weekOffset)"
                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                center.add(request) { error in
                    if let error {
                        print("Routine notification scheduling failed for \(identifier):", error)
                    }
                }
            }
        }
    }
    
    func deleteNotifications() {
        var identifiers: [String] = []
        for weekday in 1..<8 {
            for offset in 0..<2 {
                identifiers.append("routine-\(self.id)-\(weekday)-\(offset)")
            }
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    func deleteSingleNotification (weekday: Int) {
        var identifiers: [String] = []
        for offset in 0..<2 {
            identifiers.append("routine-\(self.id)-\(weekday)-\(offset)")
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
