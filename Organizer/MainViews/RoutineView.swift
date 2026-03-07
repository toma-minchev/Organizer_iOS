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
        calendar.firstWeekday = Calendar.current.firstWeekday // or a user-selected value
        return calendar.component(.weekOfYear, from: Date())
    }
    
    @State private var showingAddRoutine = false
    @State private var showActionButtons = false
    @State private var selectedDay: Weekday = {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return Weekday(rawValue: weekday)!
    }()

    var filteredRoutines: [Routine] {
        routines.filter { $0.recurrences.contains(selectedDay.rawValue) }
    }
    
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
                            selectedDay: selectedDay,
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
                
                Picker("Day", selection: $selectedDay) {
                    ForEach(orderedWeekdays) { day in
                        Text(day.shortLetter).tag(day)
                    }
                }
                .pickerStyle(.segmented)
                .background(
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color(.systemBackground))
                        .blur(radius: 5)
                )
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
        if routines.isEmpty {
            let days: [Int] = [2, 3, 4, 5, 6]
            
            for day in days {
                for i in 0..<2 {
                    let routine = Routine(
                        name: "Sample Routine",
                        details: "Seeded routine",
                        dueHour: 9 + i,
                        dueMinute: 0,
                        completions: [],
                        recurrences: [day]
                    )
                    
                    modelContext.insert(routine)
                }
            }
            
            try? modelContext.save()
        }
    }
}
