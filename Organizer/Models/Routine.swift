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
            return "Everyday"
        }
        
        if sorted == [2,3,4,5,6] {
            return "Workdays"
        }
        
        if sorted == [1,7] {
            return "Weekends"
        }
        
        let symbols = Calendar.current.shortWeekdaySymbols
        return sorted
            .map { symbols[$0 - 1].prefix(3) }
            .joined(separator: " ")
    }
    
    func scheduleNotification() {
        let center = UNUserNotificationCenter.current()
        
        for weekday in recurrences {
            var components = DateComponents()
            components.weekday = weekday
            let date = Calendar.current.date(
                bySettingHour: dueHour,
                minute: dueMinute,
                second: 0,
                of: Date()
            )!

            let triggerDate = date.addingTimeInterval(-60)

            components.hour = Calendar.current.component(.hour, from: triggerDate)
            components.minute = Calendar.current.component(.minute, from: triggerDate)
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: true
            )
            
            let content = UNMutableNotificationContent()
            content.title = "Routine \"\(name)\" due in one minute."
            content.body = details.count > 0 ? details : "Open the app for details."
            content.sound = .default
            
            let request = UNNotificationRequest(
                identifier: "routine-\(self.id)-\(weekday)",
                content: content,
                trigger: trigger
            )
            
            center.add(request) { error in
                if let error {
                    print("Notification scheduling failed:", error)
                }
            }
        }
    }
    
    func deleteNotifications () {
        for weekday in recurrences {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["routine-\(self.id)-\(weekday)"])
        }
    }
    
    func deleteSingleNotification (weekday: Int) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["routine-\(self.id)-\(weekday)"])
    }
}
