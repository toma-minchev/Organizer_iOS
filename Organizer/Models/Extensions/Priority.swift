//
//  Priority.swift
//  Organizer
//

import SwiftUI


enum Priority: Int, CaseIterable, Identifiable, Codable {
    case low    = 0
    case medium = 1
    case high   = 2

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
