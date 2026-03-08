//
//  Event.swift
//  Organizer
//
//  Created by Toma Minchev on 25.02.26.
//

import Foundation
import SwiftData


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
}
