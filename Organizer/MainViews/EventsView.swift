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
                        EventRowView(
                            event: event,
                            showActionButtons: showActionButtons
                        )
                        .onDisappear {
                            showActionButtons = false
                        }
                    }
                }
                .navigationTitle("Timeline")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        if !showActionButtons && events.count > 0 {
                            Button("Edit") {
                                withAnimation {
                                    showActionButtons = true
                                }
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
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
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
