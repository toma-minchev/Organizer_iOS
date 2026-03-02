//
//  Event.swift
//  Organizer
//
//  Created by Toma Minchev on 25.02.26.
//

import Foundation
import SwiftData


@Model
final class Event {
    var name: String
    var details: String
    var dueDate: Date
    var isCompleted: Bool
    var recurrence: Int
    
    init(name: String, details: String, dueDate: Date, isCompleted: Bool, recurrence: Int) {
        self.name = name
        self.details = details
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.recurrence = recurrence
    }
}
