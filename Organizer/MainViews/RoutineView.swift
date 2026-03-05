//
//  RoutineView.swift
//  Organizer
//
//  Created by Toma Minchev on 27.02.26.
//

import SwiftUI
import SwiftData


enum Weekday: String, CaseIterable, Identifiable {
    var id: Self { self }
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday
    var shortLetter: String {rawValue.first.map { String($0).uppercased() } ?? ""}
    var index: Int { Self.allCases.firstIndex(of: self)! + 1 }
}

struct RoutineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var routines: [Routine]
    
    @State private var showingAddRoutine = false
    @State private var showActionButtons = false
    @State private var selectedDay: Weekday = .monday

    private var filteredRoutines: [Routine] {
        let dayIndex = selectedDay.index
        return routines.filter { $0.recurrences.contains(dayIndex) }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                List {
                    ForEach(filteredRoutines) { routine in
                        NavigationLink {
                            EditRoutineView(/*routine: routine*/)
                        } label: {
                            HStack {
//                                if showActionButtons {
//                                    Button {
//                                        routine.isCompleted.toggle()
//                                    } label: {
//                                        Image(systemName: event.isCompleted ? "checkmark.circle.fill" : "circle")
//                                            .font(.system(size: 22))
//                                    }
//                                    .foregroundColor(event.isCompleted ? .green : .secondary)
//                                    .buttonStyle(.borderless)
//                                    .transition(.move(edge: .leading).combined(with: .opacity))
//                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
//                                    Text(
//                                        event.dueDate,
//                                        format: Calendar.current.isDateInToday(event.dueDate)
//                                            ? .dateTime.hour().minute()
//                                            : .dateTime.day().month().year().hour().minute()
//                                    )
//                                    .font(.subheadline)
//                                    .foregroundStyle(.secondary)
                                    
                                    Text(routine.name)
                                        .lineLimit(1)
                                        .bold()
//                                        .foregroundColor(event.isCompleted ? .secondary : .primary)
//                                        .strikethrough(event.isCompleted)
                                    
//                                    if !event.isCompleted && !event.details.isEmpty {
//                                        Text(event.details)
//                                        .font(.subheadline)
//                                        .foregroundStyle(.secondary)
//                                    }
                                }

//                                Spacer()
//
//                                if showActionButtons {
//                                    Button(role: .destructive) {
//                                        modelContext.delete(event)
//                                    } label: {
//                                        Image(systemName: "trash")
//                                            .font(.system(size: 22))
//                                    }
//                                    .foregroundColor(.red)
//                                    .buttonStyle(.borderless)
//                                    .transition(.move(edge: .trailing).combined(with: .opacity))
//                                }
                            }
                        }
                        .onDisappear {
                            showActionButtons = false
                        }
//                        .swipeActions(edge: .trailing) {
//                            Button {
//                                withAnimation {
//                                    event.isCompleted.toggle()
//                                }
//                            } label: {
//                                Label(event.isCompleted ? "Undo" : "Done", systemImage: "checkmark")
//                            }
//                            .tint(event.isCompleted ? .secondary : .blue)
//                        
//                        
//                            Button(role: .destructive) {
//                                modelContext.delete(event)
//                            } label: {
//                                Label("Delete", systemImage: "trash")
//                            }
//                        }
                    }
                }
                .contentMargins(.top, 50)
                .task {
                    seedIfNeeded()
                }
                
                Picker("Day", selection: $selectedDay) {
                    ForEach(Weekday.allCases) { day in
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !showActionButtons && filteredRoutines.count > 0 {
                        Button {
                            withAnimation {
                                showActionButtons = true
                            }
                        }
                        label: {
                            Label("Edit", systemImage: "pencil")
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

                ToolbarItem(placement: .navigationBarLeading) {
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
                AddRoutineView()
            }
        }
    }
    
    private func seedIfNeeded() {
        if routines.isEmpty {
            let workDays: [Int] = [1, 2, 3, 4, 5]
            
            for day in workDays {
                for i in 0..<2 {
                    let routine = Routine(
                        name: "Sample Routine",
                        details: "Seeded routine",
                        dueHour: 9 + i,
                        dueMinute: 0,
                        completions: [:],
                        recurrences: [day]
                    )
                    
                    modelContext.insert(routine)
                }
            }
            
            try? modelContext.save()
        }
    }
}
