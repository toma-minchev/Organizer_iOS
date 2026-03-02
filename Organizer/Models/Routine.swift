//
//  Event.swift
//  Organizer
//
//  Created by Toma Minchev on 25.02.26.
//

import Foundation
import SwiftData


@Model
final class Routine {
    var name: String
    var details: String
    var dueHour: Int
    var dueMinute: Int
    var completions: [Date: Bool] = [:]
    var recurrences: [Int] = []
    
    init(name: String, details: String, dueHour: Int, dueMinute: Int, completions: [Date: Bool], recurrence: [Int]) {
        self.name = name
        self.details = details
        self.dueHour = dueHour
        self.dueMinute = dueMinute
        self.completions = completions
        self.recurrences = recurrences
    }
}
