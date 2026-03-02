//
//  RoutineView.swift
//  Organizer
//
//  Created by Toma Minchev on 27.02.26.
//

import SwiftUI
import SwiftData


enum Weekday: String, CaseIterable, Identifiable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday
    var id: Self { self }

    var shortLetter: String {
        String(rawValue.prefix(1)).uppercased()
    }
}

struct RoutineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var events: [Event]
    
    @State private var showingAddRoutine = false
    @State private var showActionButtons = false
    @State private var selectedDay: Weekday = .monday

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                List {
                    ForEach(events) { event in
                        NavigationLink {
                            EditEventView(event: event)
                        } label: {
                            HStack {
                                if showActionButtons {
                                    Button {
                                        event.isCompleted.toggle()
                                    } label: {
                                        Image(systemName: event.isCompleted ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 22))
                                    }
                                    .foregroundColor(event.isCompleted ? .green : .secondary)
                                    .buttonStyle(.borderless)
                                    .transition(.move(edge: .leading).combined(with: .opacity))
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(
                                        event.dueDate,
                                        format: Calendar.current.isDateInToday(event.dueDate)
                                            ? .dateTime.hour().minute()
                                            : .dateTime.day().month().year().hour().minute()
                                    )
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    
                                    Text(event.name)
                                        .lineLimit(1)
                                        .bold()
                                        .foregroundColor(event.isCompleted ? .secondary : .primary)
                                        .strikethrough(event.isCompleted)
                                    
                                    if !event.isCompleted && !event.details.isEmpty {
                                        Text(event.details)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                if showActionButtons {
                                    Button(role: .destructive) {
                                        modelContext.delete(event)
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.system(size: 22))
                                    }
                                    .foregroundColor(.red)
                                    .buttonStyle(.borderless)
                                    .transition(.move(edge: .trailing).combined(with: .opacity))
                                }
                            }
                        }
                        .onDisappear {
                            showActionButtons = false
                        }
                        .swipeActions(edge: .trailing) {
                            Button {
                                withAnimation {
                                    event.isCompleted.toggle()
                                }
                            } label: {
                                Label(event.isCompleted ? "Undo" : "Done", systemImage: "checkmark")
                            }
                            .tint(event.isCompleted ? .secondary : .blue)
                        
                        
                            Button(role: .destructive) {
                                modelContext.delete(event)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .contentMargins(.top, 50)
                
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
                    if !showActionButtons && events.count > 0 {
                        Button {
                            withAnimation {
                                showActionButtons = true
                            }
                        }
                        label: {
                            Label("Edit", systemImage: "pencil")
                        }
                    } else if events.count > 0 {
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
            .sheet(isPresented: $showingAddRoutine) {
                AddRoutineView()
            }
        }
    }
}
