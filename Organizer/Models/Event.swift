//
//  Event.swift
//  Organizer
//
//  Created by Toma Minchev on 25.02.26.
//

import Foundation
import SwiftData
import UserNotifications
import SwiftUI


enum Priority: Int, CaseIterable, Identifiable, Codable {
    case low = 0
    case medium = 1
    case high = 2

    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .low:    return String(localized: "Low")
        case .medium: return String(localized: "Medium")
        case .high:   return String(localized: "High")
        }
    }
    
    var color: Color {
        switch self {
        case .low:    return .secondary
        case .medium: return .yellow
        case .high:   return .red
        }
    }
}

enum RecurrenceUnit: String, CaseIterable, Codable {
    case minute
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
    var priority: Priority
    var isCompleted: Bool
    var notify: Bool
    var notifyOffsetValue: Int
    var notifyOffsetUnit: RecurrenceUnit
    var recurrenceValue: Int
    var recurrenceUnit: RecurrenceUnit
    
    init(name: String, details: String, dueDate: Date, creationDate: Date, priority: Priority, isCompleted: Bool, notify: Bool, notifyOffsetValue: Int, notifyOffsetUnit: RecurrenceUnit, recurrenceValue: Int, recurrenceUnit: RecurrenceUnit) {
        self.name = name
        self.details = details
        self.dueDate = dueDate
        self.creationDate = creationDate
        self.priority = priority
        self.isCompleted = isCompleted
        self.notify = notify
        self.notifyOffsetValue = notifyOffsetValue
        self.notifyOffsetUnit = notifyOffsetUnit
        self.recurrenceValue = recurrenceValue
        self.recurrenceUnit = recurrenceUnit
    }
}


extension Event {
    func occurs(on date: Date) -> Bool {
        let calendar = Calendar.current

        if calendar.isDate(dueDate, inSameDayAs: date) {
            return true
        }

        guard recurrenceValue > 0 else { return false }
        guard date >= creationDate else { return false }

        switch recurrenceUnit {
            case .minute:
                return true
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
    
    func addToDueDate() {
        if isCompleted && recurrenceValue > 0 {
            let calendar = Calendar.current
            
            switch recurrenceUnit {
                case .minute: dueDate = calendar.date(byAdding: .minute, value: recurrenceValue, to: dueDate)!
                case .hour: dueDate = calendar.date(byAdding: .hour, value: recurrenceValue, to: dueDate)!
                case .day: dueDate = calendar.date(byAdding: .day, value: recurrenceValue, to: dueDate)!
                case .week: dueDate = calendar.date(byAdding: .weekOfYear, value: recurrenceValue, to: dueDate)!
                case .month: dueDate = calendar.date(byAdding: .month, value: recurrenceValue, to: dueDate)!
                case .year: dueDate = calendar.date(byAdding: .year, value: recurrenceValue, to: dueDate)!
            }
            
            isCompleted = false
        }
    }
    
    func notifyOffsetLabel() -> String {
        notifyOffsetUnit.localizedLabel(value: notifyOffsetValue)
    }
    
    func scheduleNotification() {
        guard notify else {
            deleteNotification()
            return
        }

        let offsetSeconds: Double
        switch notifyOffsetUnit {
        case .minute: offsetSeconds = Double(notifyOffsetValue) * 60
        case .hour:   offsetSeconds = Double(notifyOffsetValue) * 3600
        case .day:    offsetSeconds = Double(notifyOffsetValue) * 86400
        case .week:   offsetSeconds = Double(notifyOffsetValue) * 604800
        case .month:  offsetSeconds = Double(notifyOffsetValue) * 2592000
        case .year:   offsetSeconds = Double(notifyOffsetValue) * 31536000
        }

        let triggerDate = dueDate.addingTimeInterval(-offsetSeconds)
        guard triggerDate > Date() else { return }

        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        let details = details.isEmpty ? String(localized: .notificationDefaultText) : details
        content.title = String(name)
        content.body = notifyOffsetValue > 0 ? String(localized: .eventNotificationText(dueTime: notifyOffsetLabel())) : details
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


extension RecurrenceUnit {
    func localizedLabel(value: Int) -> String {
        switch self {
            case .minute: return value == 1 ? String(localized: "Minute") : String(localized: "Minutes")
            case .hour:  return value == 1 ? String(localized: "Hour")  : String(localized: "Hours")
            case .day:   return value == 1 ? String(localized: "Day")   : String(localized: "Days")
            case .week:  return value == 1 ? String(localized: "Week")  : String(localized: "Weeks")
            case .month: return value == 1 ? String(localized: "Month") : String(localized: "Months")
            case .year:  return value == 1 ? String(localized: "Year")  : String(localized: "Years")
        }
    }
    
    func recurrenceDescription(recurrenceUnit: RecurrenceUnit, recurrenceValue: Int) -> String {
        if recurrenceValue == 0 {
            return String(localized: "No repeat")
        }

        switch recurrenceUnit {
            case .minute:
                return recurrenceValue == 1
                ? String(localized: "Every miunte")
                : String(localized: "Every \(recurrenceValue) minutes")
            
            case .hour:
                return recurrenceValue == 1
                ? String(localized: "Every hour")
                : String(localized: "Every \(recurrenceValue) hours")

            case .day:
                return recurrenceValue == 1
                ? String(localized: "Every day")
                : String(localized: "Every \(recurrenceValue) days")

            case .week:
                return recurrenceValue == 1
                ? String(localized: "Every week")
                : String(localized: "Every \(recurrenceValue) weeks")

            case .month:
                return recurrenceValue == 1
                ? String(localized: "Every month")
                : String(localized: "Every \(recurrenceValue) months")

            case .year:
                return recurrenceValue == 1
                ? String(localized: "Every year")
                : String(localized: "Every \(recurrenceValue) years")
        }
    }
    
    static func recurrenceRange(recurrenceUnit: RecurrenceUnit) -> ClosedRange<Int> {
        switch recurrenceUnit {
            case .minute: return 1...59
            case .hour: return 1...23
            case .day: return 1...6
            case .week: return 1...3
            case .month: return 1...11
            case .year: return 1...10
        }
    }
}
