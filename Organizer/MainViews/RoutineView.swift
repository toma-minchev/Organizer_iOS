//
//  RoutineView.swift
//  Organizer
//
//  Created by Toma Minchev on 27.02.26.
//

import SwiftUI
import SwiftData


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
        String(String(describing: self).prefix(1)).uppercased()
    }
}

struct RoutineView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: [SortDescriptor(\Routine.dueHour), SortDescriptor(\Routine.dueMinute)])
    private var routines: [Routine]
    
    @AppStorage("lastWeekNumber") private var lastWeekNumber: Int = 0
    private var currentWeekNumber: Int {
        var calendar = Calendar.current
        calendar.firstWeekday = Calendar.current.firstWeekday
        return calendar.component(.weekOfYear, from: Date())
    }
    
    @State private var showingAddRoutine = false
    @State private var showActionButtons = false
    @State private var selectedWeekday: Weekday = {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return Weekday(rawValue: weekday)!
    }()

    var filteredRoutines: [Routine] { routines.filter { $0.recurrences.contains(selectedWeekday.rawValue) } }
    
    private var orderedWeekdays: [Weekday] {
        let first = Calendar.current.firstWeekday
        guard let index = Weekday.allCases.firstIndex(where: { $0.rawValue == first }) else {
            return Weekday.allCases
        }
        return Array(Weekday.allCases[index...] + Weekday.allCases[..<index])
    }
    
    private func resetRoutinesIfNewWeek() {
        var calendar = Calendar.current
        calendar.firstWeekday = Calendar.current.firstWeekday
        let currentWeek = calendar.component(.weekOfYear, from: Date())
        guard currentWeek != lastWeekNumber else { return }
        
        for routine in routines {
            routine.completions = []
        }
        
        try? modelContext.save()
        lastWeekNumber = currentWeek
    }

    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                List {
                    ForEach(filteredRoutines) { routine in
                        RoutineRowView(
                            routine: routine,
                            selectedWeekday: selectedWeekday,
                            showActionButtons: showActionButtons,
                            orderedWeekdays: orderedWeekdays
                        )
                    }
                }
                .contentMargins(.top, 50)
                .task {
                    resetRoutinesIfNewWeek()
                    seedIfNeeded()
                }
                
                Picker("Day", selection: $selectedWeekday) {
                    ForEach(orderedWeekdays) { day in
                        Text(day.shortLetter).tag(day)
                    }
                }
                .pickerStyle(.segmented)
                .background(Capsule().fill(.regularMaterial))
                .padding(.horizontal)
                .padding(.top, 7)
                .zIndex(1)
            }
            .toolbarBackground(.hidden)
            .navigationTitle("Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !showActionButtons && filteredRoutines.count > 0 {
                        Button("Edit") {
                            withAnimation {
                                showActionButtons = true
                            }
                        }
                    } else if filteredRoutines.count > 0 {
                        Button(role: .confirm) {
                            withAnimation {
                                showActionButtons = false
                            }
                        }
                        label: {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !showActionButtons {
                        Button { showingAddRoutine = true }
                        label: { Label("Add Event", systemImage: "plus") }
                    }
                }
            }
            .overlay {
                if filteredRoutines.isEmpty {
                    ContentUnavailableView(
                        "No Routine",
                        systemImage: "repeat.circle",
                        description: Text("There is no routine for this day.")
                    )
                }
            }
            .sheet(isPresented: $showingAddRoutine) {
                AddRoutineView(orderedWeekdays: orderedWeekdays)
            }
        }
    }
    
    private func seedIfNeeded() {
        guard routines.isEmpty else { return }
        
        let routineTemplates: [(name: String, details: String, hour: Int, minute: Int, days: [Int])] = [
            ("Morning Jog", "Jog for 30 minutes", 6, 30, [2,3,4,5,6]),
            ("Drink Water", "Drink a glass of water", 9, 0, [1,2,3,4,5,6,7]),
            ("Read Book", "Read 20 pages", 20, 0, [2,4,6]),
            ("Meditation", "10 minutes meditation", 7, 0, [1,2,3,4,5,6,7]),
            ("Weekly Call", "Call parents", 18, 0, [7])
        ]
        
        for template in routineTemplates {
            let routine = Routine(
                name: template.name,
                details: template.details,
                dueHour: template.hour,
                dueMinute: template.minute,
                completions: [],
                recurrences: template.days
            )
            modelContext.insert(routine)
        }
        
        try? modelContext.save()
    }
}
