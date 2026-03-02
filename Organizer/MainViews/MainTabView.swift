//
//  MainTabView.swift
//  Organizer
//
//  Created by Toma Minchev on 27.02.26.
//
import SwiftUI
import SwiftData

struct MainTabView: View {
    var body: some View {
        TabView() {
            EventsView()
                .tabItem {
                    Label("Timeline", systemImage: "calendar")
                }

            RoutineView()
                .tabItem {
                    Label("Routine", systemImage: "square.grid.2x2")
                }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: Event.self, inMemory: false)
}
