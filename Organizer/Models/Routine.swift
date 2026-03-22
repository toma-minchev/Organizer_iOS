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
    var completions: [Int] = []
    var recurrences: [Int] = []
    
    init(name: String, details: String, dueHour: Int, dueMinute: Int, completions: [Int], recurrences: [Int]) {
        self.name = name
        self.details = details
        self.dueHour = dueHour
        self.dueMinute = dueMinute
        self.completions = completions
        self.recurrences = recurrences
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
    
    func scheduleNotification() {
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        
        deleteNotifications()
        
        for weekOffset in 0..<2 {
            for weekday in recurrences {
                guard let baseNextDate = calendar.nextDate(
                    after: Date(),
                    matching: DateComponents(hour: dueHour, minute: dueMinute, weekday: weekday),
                    matchingPolicy: .nextTime
                ) else { continue }
                
                guard let nextDate = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: baseNextDate) else { continue }
                
                let triggerDate = nextDate.addingTimeInterval(-60)
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
