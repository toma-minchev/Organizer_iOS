//
//  TimelineView.swift
//  Organizer
//
//  Created by Toma Minchev on 25.02.26.
//

import SwiftUI
import SwiftData

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor(\Event.dueDate)]) private var events: [Event]
    @Query(sort: [SortDescriptor(\Routine.dueHour), SortDescriptor(\Routine.dueMinute)]) private var routines: [Routine]

    @State private var viewModel = TimelineViewModel()

    let selectedTab: Int
    

    var body: some View {
        @Bindable var vm = viewModel

        NavigationStack {
            ZStack(alignment: .top) {
                ZStack {
                    List {
                        if viewModel.showPeriods {
                            ForEach(viewModel.activeGroups(events: events, routines: routines), id: \.name) { group in
                                Section {
                                    if !viewModel.collapsedGroups.contains(group.name) {
                                        ForEach(group.items, id: \.persistentModelID) {
                                            rowView(for: $0)
                                        }
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                    }
                                } header: {
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            viewModel.toggleCollapse(for: group.name)
                                        }
                                    } label: {
                                        HStack {
                                            Text(group.name)
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                                .rotationEffect(
                                                    viewModel.collapsedGroups.contains(group.name)
                                                        ? .degrees(-90) : .degrees(0)
                                                )
                                                .animation(.easeInOut(duration: 0.25), value: viewModel.collapsedGroups)
                                        }
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        if !viewModel.showPeriods {
                            ForEach(viewModel.timelineItems(events: events, routines: routines), id: \.persistentModelID) {
                                rowView(for: $0)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .id(viewModel.selectedDate)
                    .contentMargins(.top, 50)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.4), value: viewModel.showRoutines)
                    .animation(.easeInOut(duration: 0.4), value: viewModel.showPeriods)
                    .animation(.easeInOut(duration: 0.6), value: viewModel.selectedDate)
                    .gesture(
                        DragGesture(minimumDistance: 50, coordinateSpace: .local)
                        .onEnded { value in
                            let h = value.translation.width
                            let v = value.translation.height
                            if abs(h) > abs(v) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    viewModel.navigateDay(forward: h < 0)
                                }
                            }
                        }
                    )
                    .overlay {
                        let filteredEvents   = viewModel.filteredEvents(from: events)
                        let filteredRoutines = viewModel.filteredRoutines(from: routines)

                        if filteredEvents.isEmpty && !viewModel.showRoutines {
                            ContentUnavailableView(
                                "No Events",
                                systemImage: "list.bullet",
                                description: Text("There are no events for this date.")
                            )
                        } else if filteredEvents.isEmpty && viewModel.showRoutines && filteredRoutines.isEmpty {
                            ContentUnavailableView(
                                "Nothing Scheduled",
                                systemImage: "list.bullet",
                                description: Text("There are no items for this date.")
                            )
                        }
                    }
                }

                // MARK: - Floating Control Bar

                HStack {
                    HStack(spacing: 8) {
                        Button {
                            viewModel.showDatePicker = true
                        } label: {
                            Text(viewModel.selectedDate.formatted(date: .abbreviated, time: .omitted))
                                .foregroundColor(.primary)
                                .frame(maxHeight: .infinity)
                                .font(.system(size: 14))
                                .fontWeight(.medium)
                                .padding(.horizontal, 10)
                                .background(Capsule().fill(Color("CustomGray")))
                        }
                        .frame(maxHeight: 26)
                        .popover(isPresented: $vm.showDatePicker) {
                            DatePicker("", selection: $vm.selectedDate, displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .frame(width: 320)
                                .padding(.horizontal, 10)
                                .presentationCompactAdaptation(.popover)
                        }

                        Spacer()

                        if viewModel.showPeriods {
                            Button {
                                viewModel.sortByPriority.toggle()
                            } label: {
                                Image(systemName: "flag")
                                    .foregroundColor(viewModel.sortByPriority ? .white : .primary)
                                    .frame(width: 50)
                                    .frame(maxHeight: 26)
                                    .background(Capsule().fill(viewModel.sortByPriority ? Color.accentColor : Color("CustomGray")))
                            }
                            .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.sortByPriority)
                        }

                        Button {
                            viewModel.showPeriods.toggle()
                        } label: {
                            Image(systemName: "list.bullet.indent")
                                .foregroundColor(viewModel.showPeriods ? .white : .primary)
                                .frame(width: 50)
                                .frame(maxHeight: 26)
                                .background(Capsule().fill(viewModel.showPeriods ? Color.accentColor : Color("CustomGray")))
                        }
                        .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.showPeriods)

                        Button {
                            viewModel.showRoutines.toggle()
                        } label: {
                            Image(systemName: "repeat")
                                .foregroundColor(viewModel.showRoutines ? .white : .primary)
                                .frame(width: 50)
                                .frame(maxHeight: 26)
                                .background(Capsule().fill(viewModel.showRoutines ? Color.accentColor : Color("CustomGray")))
                        }
                        .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.showRoutines)
                    }
                    .padding(3)
                }
                .background(Capsule().fill(Color(.secondarySystemFill)))
                .background(Capsule().fill(.ultraThinMaterial))
                .padding(.horizontal)
                .padding(.top, 7)
                .zIndex(1)
            }
            .navigationTitle("Timeline")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !viewModel.showActionButtons && events.count > 0 {
                        Button("Edit") {
                            withAnimation { viewModel.showActionButtons = true }
                        }
                    } else if events.count > 0 {
                        Button(role: .confirm) {
                            withAnimation { viewModel.showActionButtons = false }
                        } label: {
                            Image(systemName: "checkmark")
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewModel.showActionButtons {
                        Button { viewModel.addEventItem = AddEventContext(duplicatedEvent: nil) }
                        label: { Label("Add Event", systemImage: "plus") }
                    }
                }
            }
            .onDisappear {
                viewModel.showActionButtons = false
            }
            .sheet(item: $vm.addEventItem) { context in
                AddEventView(selectedDate: viewModel.selectedDate, duplicatedEvent: context.duplicatedEvent)
            }
            .sheet(item: $vm.addRoutineItem) { context in
                AddRoutineView(orderedWeekdays: viewModel.orderedWeekdays, duplicatedRoutine: context.duplicatedRoutine)
            }
//            .task {
//                viewModel.seedIfNeeded(events: events, modelContext: modelContext)
//            }
        }
    }

    // MARK: - Row Builder

    @ViewBuilder
    private func rowView(for item: any TimelineEntry) -> some View {
        if let event = item as? Event {
            EventRowView(
                event: event,
                showRoutines: viewModel.showRoutines,
                showActionButtons: viewModel.showActionButtons,
                selectedDate: viewModel.selectedDate,
                selectedTab: selectedTab,
                onDuplicate: { event in
                    viewModel.addEventItem = AddEventContext(duplicatedEvent: event)
                }
            )
        }
        if let routine = item as? Routine {
            RoutineRowView(
                routine: routine,
                selectedWeekday: Weekday(rawValue: viewModel.selectedWeekday)!,
                showActionButtons: viewModel.showActionButtons,
                orderedWeekdays: viewModel.orderedWeekdays,
                selectedTab: selectedTab,
                onDuplicate: { routine in
                    viewModel.addRoutineItem = AddRoutineContext(duplicatedRoutine: routine)
                }
            )
        }
    }
}
