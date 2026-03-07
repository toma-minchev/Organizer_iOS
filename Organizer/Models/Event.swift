//
//  Event.swift
//  Organizer
//
//  Created by Toma Minchev on 25.02.26.
//

import Foundation
import SwiftData


enum RecurrenceUnit: String, CaseIterable, Codable {
    case hour
    case day
    case week
    case month
    case year
}

@Model
final class Event {
    var name: String
    var details: String
    var dueDate: Date
    var isCompleted: Bool
    var recurrenceValue: Int
    var recurrenceUnit: RecurrenceUnit
    
    init(name: String, details: String, dueDate: Date, isCompleted: Bool, recurrenceValue: Int, recurrenceUnit: RecurrenceUnit) {
        self.name = name
        self.details = details
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.recurrenceValue = recurrenceValue
        self.recurrenceUnit = recurrenceUnit
    }
}


extension Event {
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
}

