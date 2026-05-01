//
//  MainTabView.swift
//  Organizer
//
//  Created by Toma Minchev on 27.02.26.
//
import SwiftUI
import SwiftData


struct MainTabView: View {
    @State private var selectedTab: Int = 0
    

    var body: some View {
        TabView(selection: $selectedTab) {
            TimelineView(selectedTab: selectedTab)
            .tabItem {
                Label("Timeline", systemImage: "list.bullet")
            }
            .tag(0)

            RoutineView(selectedTab: selectedTab)
            .tabItem {
                Label("Routine", systemImage: "repeat")
            }
            .tag(1)
        }
    }
}

