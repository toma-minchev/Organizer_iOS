//
//  OrganizerApp.swift
//  Organizer
//
//  Created by Toma Minchev on 25.02.26.
//

import SwiftUI
import SwiftData


@main
struct OrganizerApp: App {
    let notificationDelegate = NotificationDelegate()
       
    init() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Event.self,
            Routine.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .modelContainer(sharedModelContainer)
                .task { NotificationManager.shared.requestPermission() }
        }
    }
}
