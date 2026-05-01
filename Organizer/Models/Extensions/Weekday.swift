//
//  Weekday.swift
//  Organizer
//

import Foundation


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
