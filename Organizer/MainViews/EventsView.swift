//
//  ContentView.swift
//  Organizer
//
//  Created by Toma Minchev on 25.02.26.
//

import SwiftUI
import SwiftData

struct EventsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var events: [Event]
    
    @State private var showingAddEvent = false
    @State private var showActionButtons = false
    @State private var selectedDate = Date()
    
    private var filteredEvents: [Event] {
        events.filter { event in
            Calendar.current.isDate(event.dueDate, inSameDayAs: selectedDate)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                List {
                    ForEach(filteredEvents) { event in
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
                .navigationTitle("Timeline")
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
                            Button { showingAddEvent = true }
                            label: { Label("Add Event", systemImage: "plus") }
                        }
                    }
                }.overlay {
                    if filteredEvents.isEmpty {
                        ContentUnavailableView(
                            "No Events",
                            systemImage: "calendar",
                            description: Text("There are no events for this date.")
                        )
                    }
                }
                .sheet(isPresented: $showingAddEvent) {
                    AddEventView()
                }
                .contentMargins(.top, 50)
                .task {
                    seedIfNeeded()
                }

                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .background(
                        RoundedRectangle(cornerRadius: 0)
                        .fill(Color(.systemBackground))
                        .blur(radius: 5)
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .padding(.horizontal)
                    .padding(.top, 7)
                    .zIndex(1)
            }
        }
    }
    
    private func seedIfNeeded() {
        if events.isEmpty {
            let calendar = Calendar.current
            let today = Date()
            
            let dates = [
                calendar.date(byAdding: .day, value: -1, to: today)!,
                today,
                calendar.date(byAdding: .day, value: 1, to: today)!
            ]
            
            for date in dates {
                for _ in 0..<4 {
                    let event = Event(
                        name: "Sample Event",
                        details: "Seeded event",
                        dueDate: date,
                        isCompleted: false,
                        recurrence: 0
                    )
                    
                    modelContext.insert(event)
                }
            }
            
            try? modelContext.save()
        }
    }

    private func deleteEvents(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(events[index])
            }
        }
    }
}
