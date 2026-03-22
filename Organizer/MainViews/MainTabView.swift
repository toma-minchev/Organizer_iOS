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
            TimelineView()
            .tabItem {
                Label("Timeline", systemImage: "list.bullet")
            }

            RoutineView()
            .tabItem {
                Label("Routine", systemImage: "repeat")
            }
        }
    }
}

#Preview {
    MainTabView()
}

