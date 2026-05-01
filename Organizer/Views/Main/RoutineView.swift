//
//  RoutineView.swift
//  Organizer
//
//  Created by Toma Minchev on 27.02.26.
//

import SwiftUI
import SwiftData

struct RoutineView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor(\Routine.dueHour), SortDescriptor(\Routine.dueMinute)])
    private var routines: [Routine]

    @State private var viewModel = RoutineViewModel()

    let selectedTab: Int
    

    var body: some View {
        let filtered = viewModel.filteredRoutines(from: routines)

        NavigationStack {
            ZStack(alignment: .top) {
                ZStack {
                    List {
                        ForEach(filtered) { routine in
                            RoutineRowView(
                                routine: routine,
                                selectedWeekday: viewModel.selectedWeekday,
                                showActionButtons: viewModel.showActionButtons,
                                orderedWeekdays: viewModel.orderedWeekdays,
                                selectedTab: selectedTab,
                                onDuplicate: { routine in
                                    viewModel.addRoutineItem = AddRoutineContext(duplicatedRoutine: routine)
                                }
                            )
                        }
                    }
                    .id(viewModel.selectedWeekday)
                    .contentMargins(.top, 50)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: filtered)
                    .gesture(
                        DragGesture(minimumDistance: 50, coordinateSpace: .local)
                            .onEnded { value in
                                let horizontalAmount = value.translation.width
                                let verticalAmount = value.translation.height
                                guard abs(horizontalAmount) > abs(verticalAmount) else { return }
                                if horizontalAmount < 0 {
                                    viewModel.navigateToNextDay()
                                } else {
                                    viewModel.navigateToPreviousDay()
                                }
                            }
                    )
                    .overlay {
                        if filtered.isEmpty {
                            ContentUnavailableView(
                                "No Routine",
                                systemImage: "repeat.circle",
                                description: Text("There is no routine for this day.")
                            )
                        }
                    }
                }

                Picker("Day", selection: $viewModel.selectedWeekday) {
                    ForEach(viewModel.orderedWeekdays) { day in
                        Text(day.shortLetter).tag(day)
                    }
                }
                .pickerStyle(.segmented)
                .background(Capsule().fill(.ultraThinMaterial))
                .padding(.horizontal)
                .padding(.top, 7)
                .zIndex(1)
            }
            .toolbarBackground(.hidden)
            .navigationTitle("Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !viewModel.showActionButtons && !filtered.isEmpty {
                        Button("Edit") {
                            withAnimation { viewModel.showActionButtons = true }
                        }
                    } else if !filtered.isEmpty {
                        Button(role: .confirm) {
                            withAnimation { viewModel.showActionButtons = false }
                        } label: {
                            Image(systemName: "checkmark")
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewModel.showActionButtons {
                        Button {
                            viewModel.addRoutineItem = AddRoutineContext(duplicatedRoutine: nil)
                        } label: {
                            Label("Add Event", systemImage: "plus")
                        }
                    }
                }
            }
            .onDisappear {
                viewModel.showActionButtons = false
            }
            .sheet(item: $viewModel.addRoutineItem) { context in
                AddRoutineView(
                    orderedWeekdays: viewModel.orderedWeekdays,
                    duplicatedRoutine: context.duplicatedRoutine
                )
            }
            .task {
                viewModel.schedulePausedNotificationsReminder()
                viewModel.resetRoutinesIfNewWeek(routines: routines, modelContext: modelContext)
                viewModel.seedIfNeeded(routines: routines, modelContext: modelContext)
            }
        }
    }
}
