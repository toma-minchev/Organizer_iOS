//
//  TimelineViewModel.swift
//  Organizer
//

import SwiftUI
import SwiftData


@Observable
final class TimelineViewModel {

    // MARK: - Persisted State (UserDefaults-backed, mirrors @AppStorage)

    var sortByPriority: Bool {
        didSet {
            UserDefaults.standard.set(sortByPriority, forKey: "sortByPriority")
            if sortByPriority { showRoutines = false }
        }
    }

    var showPeriods: Bool {
        didSet {
            UserDefaults.standard.set(showPeriods, forKey: "showPeriods")
            if showPeriods { sortByPriority = false }
        }
    }

    var showRoutines: Bool {
        didSet {
            UserDefaults.standard.set(showRoutines, forKey: "showRoutines")
            if showRoutines { sortByPriority = false }
        }
    }

    // MARK: - UI State

    var slideDirection: Edge = .trailing
    var showDatePicker: Bool = false
    var showActionButtons: Bool = false
    var selectedDate: Date = Date()
    var collapsedGroups: Set<String> = []
    var addEventItem: AddEventContext? = nil
    var addRoutineItem: AddRoutineContext? = nil

    // MARK: - Init

    init() {
        // Read persisted values; default showPeriods/showRoutines to true when not previously set
        sortByPriority = UserDefaults.standard.bool(forKey: "sortByPriority")
        showPeriods    = UserDefaults.standard.object(forKey: "showPeriods")  as? Bool ?? true
        showRoutines   = UserDefaults.standard.object(forKey: "showRoutines") as? Bool ?? true
    }

    // MARK: - Static Helpers

    var orderedWeekdays: [Weekday] { Weekday.allCases }

    var selectedWeekday: Int {
        Calendar.current.component(.weekday, from: selectedDate)
    }

    // MARK: - Filtered Collections

    func filteredEvents(from events: [Event]) -> [Event] {
        events.filter { $0.occurs(on: selectedDate) }
    }

    func filteredRoutines(from routines: [Routine]) -> [Routine] {
        routines.filter { $0.recurrences.contains(selectedWeekday) }
    }

    // MARK: - Timeline Composition

    func timelineItems(events: [Event], routines: [Routine]) -> [any TimelineEntry] {
        let routineItems = showRoutines ? filteredRoutines(from: routines) : []
        let combined: [any TimelineEntry] = filteredEvents(from: events) + routineItems
        return combined.sorted { a, b in
            if a.secondsFromMidnight != b.secondsFromMidnight {
                return a.secondsFromMidnight < b.secondsFromMidnight
            }
            return (a is Routine ? 1 : 0) < (b is Routine ? 1 : 0)
        }
    }

    func groupedTimelineItems(events: [Event], routines: [Routine]) -> [(name: String, items: [any TimelineEntry])] {
        let items = timelineItems(events: events, routines: routines)
        return TimePeriod.allCases.compactMap { period -> (name: String, items: [any TimelineEntry])? in
            let periodItems: [any TimelineEntry] = items.filter { period.range.contains($0.secondsFromMidnight) }
            guard !periodItems.isEmpty else { return nil }
            return (period.title, periodItems)
        }
    }

    func groupedByPriority(events: [Event], routines: [Routine]) -> [(name: String, items: [any TimelineEntry])] {
        let items = timelineItems(events: events, routines: routines)
        return Priority.allCases.reversed().compactMap { priority -> (name: String, items: [any TimelineEntry])? in
            let priorityItems: [any TimelineEntry] = items.filter { ($0 as? Event)?.priority == priority }
            guard !priorityItems.isEmpty else { return nil }
            return (priority.title, priorityItems)
        }
    }

    func activeGroups(events: [Event], routines: [Routine]) -> [(name: String, items: [any TimelineEntry])] {
        sortByPriority
            ? groupedByPriority(events: events, routines: routines)
            : groupedTimelineItems(events: events, routines: routines)
    }

    // MARK: - Actions

    func toggleCollapse(for groupName: String) {
        if collapsedGroups.contains(groupName) {
            collapsedGroups.remove(groupName)
        } else {
            collapsedGroups.insert(groupName)
        }
    }

    func navigateDay(forward: Bool) {
        slideDirection = forward ? .trailing : .leading
        selectedDate = Calendar.current.date(
            byAdding: .day,
            value: forward ? 1 : -1,
            to: selectedDate
        )!
    }

    // MARK: - Seeding

    func seedIfNeeded(events: [Event], modelContext: ModelContext) {
        guard events.isEmpty else { return }

        let calendar = Calendar.current
        let today = Date()

        let eventTemplates: [(
            name: String, details: String, offsetDays: Int, hour: Int, minute: Int,
            priority: Priority, isCompleted: Bool,
            notify: Bool, notifyOffsetValue: Int, notifyOffsetUnit: RecurrenceUnit,
            recurrenceValue: Int, recurrenceUnit: RecurrenceUnit
        )] = [
            ("Скръм дейли",       "Синхрон с екипа в Meet",              0,  9, 30, .medium, false, true,  10, .minute, 1, .day),
            ("Код ревю",          "Прегледай PR-ите преди merge",         1, 11,  0, .high,   false, true,  15, .minute, 0, .day),
            ("Среща с клиента",   "Демо на новите функции пред клиента",  3, 14,  0, .high,   false, true,  30, .minute, 0, .day),
            ("Плащане на сметки", "Ток, интернет и абонаменти",           5, 12,  0, .medium, false, true,   1, .day,    1, .month),
            ("Спринт планиране",  "Планиране на задачите за спринта",     0, 10,  0, .high,   false, true,  20, .minute, 2, .week),
            ("Бек-ъп на проекти", "Качи локалните репота в облака",       1, 20,  0, .low,    false, true,   1, .hour,   1, .week),
            ("Актуализирай CV",   "Добави последните проекти и умения",  14,  9,  0, .low,    false, true,   1, .day,    1, .year),
            ("Прегледай задачи",  "Провери Jira и затвори стари тикети",  0, 17, 30, .medium, false, true,  15, .minute, 1, .day),
        ]

        for template in eventTemplates {
            guard let dueDate = calendar.date(byAdding: .day, value: template.offsetDays, to: today) else { continue }

            let event = Event(
                name: template.name,
                details: template.details,
                dueDate: calendar.date(
                    bySettingHour: template.hour,
                    minute: template.minute,
                    second: 0,
                    of: dueDate
                ) ?? dueDate,
                creationDate: today,
                priority: template.priority,
                isCompleted: template.isCompleted,
                notify: template.notify,
                notifyOffsetValue: template.notifyOffsetValue,
                notifyOffsetUnit: template.notifyOffsetUnit,
                recurrenceValue: template.recurrenceValue,
                recurrenceUnit: template.recurrenceUnit
            )

            modelContext.insert(event)
            event.scheduleNotification()
        }

        try? modelContext.save()
    }
}
