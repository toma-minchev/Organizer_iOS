//
//  RecurrenceUnit.swift
//  Organizer
//

import Foundation


enum RecurrenceUnit: String, CaseIterable, Codable {
    case minute
    case hour
    case day
    case week
    case month
    case year
}

extension RecurrenceUnit {
    func localizedLabel(value: Int) -> String {
        switch self {
        case .minute: return value == 1 ? String(localized: "Minute") : String(localized: "Minutes")
        case .hour:   return value == 1 ? String(localized: "Hour")   : String(localized: "Hours")
        case .day:    return value == 1 ? String(localized: "Day")     : String(localized: "Days")
        case .week:   return value == 1 ? String(localized: "Week")    : String(localized: "Weeks")
        case .month:  return value == 1 ? String(localized: "Month")   : String(localized: "Months")
        case .year:   return value == 1 ? String(localized: "Year")    : String(localized: "Years")
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
        case .hour:   return 1...23
        case .day:    return 1...6
        case .week:   return 1...3
        case .month:  return 1...11
        case .year:   return 1...10
        }
    }
}
