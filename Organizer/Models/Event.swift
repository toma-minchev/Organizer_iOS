//
//  Event.swift
//  Organizer
//
//  Created by Toma Minchev on 25.02.26.
//

import Foundation
import SwiftData
import UserNotifications


enum RecurrenceUnit: String, CaseIterable, Codable {
    case hour
    case day
    case week
    case month
    case year
}

@Model
final class Event: TimelineEntry {
    var secondsFromMidnight: Int {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.hour, .minute, .second], from: dueDate)
        return (comps.hour ?? 0) * 3600 + (comps.minute ?? 0) * 60 + (comps.second ?? 0)
    }
    
    var name: String
    var details: String
    var dueDate: Date
    var creationDate: Date
    var isCompleted: Bool
    var recurrenceValue: Int
    var recurrenceUnit: RecurrenceUnit
    
    init(name: String, details: String, dueDate: Date, creationDate: Date, isCompleted: Bool, recurrenceValue: Int, recurrenceUnit: RecurrenceUnit) {
        self.name = name
        self.details = details
        self.dueDate = dueDate
        self.creationDate = creationDate
        self.isCompleted = isCompleted
        self.recurrenceValue = recurrenceValue
        self.recurrenceUnit = recurrenceUnit
    }
}


extension Event {
    func addToDueDate() {
        if isCompleted && recurrenceValue > 0 {
            let calendar = Calendar.current
            
            switch recurrenceUnit {
                case .hour: dueDate = calendar.date(byAdding: .hour, value: recurrenceValue, to: dueDate)!
                case .day: dueDate = calendar.date(byAdding: .day, value: recurrenceValue, to: dueDate)!
                case .week: dueDate = calendar.date(byAdding: .weekOfYear, value: recurrenceValue, to: dueDate)!
                case .month: dueDate = calendar.date(byAdding: .month, value: recurrenceValue, to: dueDate)!
                case .year: dueDate = calendar.date(byAdding: .year, value: recurrenceValue, to: dueDate)!
            }
            
            isCompleted = false
        }
    }
    
    var recurrenceDescription: String {
        if recurrenceValue == 0 {
            return "No repeat"
        }

        switch recurrenceUnit {
            case .hour:
                return recurrenceValue == 1
                ? "Every hour"
                : "Every \(recurrenceValue) hours"

            case .day:
                return recurrenceValue == 1
                ? "Every day"
                : "Every \(recurrenceValue) days"

            case .week:
                return recurrenceValue == 1
                ? "Every week"
                : "Every \(recurrenceValue) weeks"

            case .month:
                return recurrenceValue == 1
                ? "Every month"
                : "Every \(recurrenceValue) months"

            case .year:
                return recurrenceValue == 1
                ? "Every year"
                : "Every \(recurrenceValue) years"
        }
    }
    
    func occurs(on date: Date) -> Bool {
        let calendar = Calendar.current

        if calendar.isDate(dueDate, inSameDayAs: date) {
            return true
        }

        guard recurrenceValue > 0 else { return false }
        guard date >= creationDate else { return false }

        switch recurrenceUnit {
            case .hour:
                return true
            case .day:
                let days = calendar.dateComponents([.day], from: dueDate, to: date).day ?? 0
                return days % recurrenceValue == 0
            case .week:
                let weeks = calendar.dateComponents([.weekOfYear], from: dueDate, to: date).weekOfYear ?? 0
                let sameWeekday = calendar.component(.weekday, from: date) == calendar.component(.weekday, from: dueDate)
                return sameWeekday && weeks % recurrenceValue == 0

            case .month:
                let months = calendar.dateComponents([.month], from: dueDate, to: date).month ?? 0
                let sameDay = calendar.component(.day, from: date) == calendar.component(.day, from: dueDate)
                return sameDay && months % recurrenceValue == 0

            case .year:
                let years = calendar.dateComponents([.year], from: dueDate, to: date).year ?? 0
                let sameMonth = calendar.component(.month, from: date) == calendar.component(.month, from: dueDate)
                let sameDay = calendar.component(.day, from: date) == calendar.component(.day, from: dueDate)
                return sameMonth && sameDay && years % recurrenceValue == 0
        }
    }
    
    static func recurrenceRange(for unit: RecurrenceUnit) -> ClosedRange<Int> {
        switch unit {
            case .hour: return 1...23
            case .day: return 1...6
            case .week: return 1...3
            case .month: return 1...11
            case .year: return 1...10
        }
    }
    
    static func unitText(text: String, value: Int) -> String {
        return "\(text.capitalized)\(value == 1 ? "" : "s")"
    }
    
    func scheduleNotification() {
        let triggerDate = dueDate.addingTimeInterval(-60)
        guard triggerDate > Date() else { return }
        
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = "Event \"\(name)\" due in one minute."
        content.body = details.count > 0 ? details : "Open the app for details."
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: triggerDate
            ),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "event-\(self.id)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error {
                print("Notification scheduling failed:", error)
            }
        }
    }
    
    func deleteNotification () {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["event-\(self.id)"])
    }
}
