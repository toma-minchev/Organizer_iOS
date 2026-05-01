//
//  TimelineTypes.swift
//  Organizer
//

import SwiftUI
import SwiftData


// MARK: - Protocol

protocol TimelineEntry {
    var secondsFromMidnight: Int { get }
    var persistentModelID: PersistentIdentifier { get }
}

// MARK: - Enums

enum TimePeriod: String, CaseIterable {
    case morning
    case midday
    case afternoon
    case evening
    case night

    var title: String {
        switch self {
        case .morning:   return String(localized: "Morning")
        case .midday:    return String(localized: "Midday")
        case .afternoon: return String(localized: "Afternoon")
        case .evening:   return String(localized: "Evening")
        case .night:     return String(localized: "Night")
        }
    }

    var range: Range<Int> {
        switch self {
        case .morning:   return 0        ..< 9  * 3600
        case .midday:    return 9*3600   ..< 12 * 3600
        case .afternoon: return 12*3600  ..< 17 * 3600
        case .evening:   return 17*3600  ..< 20 * 3600
        case .night:     return 20*3600  ..< 24 * 3600
        }
    }
}

// MARK: - Contexts

struct AddEventContext: Identifiable {
    let id = UUID()
    let duplicatedEvent: Event?
}

struct AddRoutineContext: Identifiable {
    let id = UUID()
    let duplicatedRoutine: Routine?
}
