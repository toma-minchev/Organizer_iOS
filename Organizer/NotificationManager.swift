//
//  NotificationManager.swift
//  Organizer
//
//  Created by Toma Minchev on 9.03.26.
//


import UserNotifications

final class NotificationManager {
    
    static let shared = NotificationManager()
    
    func requestPermission() {
        let center = UNUserNotificationCenter.current()
        
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                print("Notification permission error:", error)
            }
        }
    }
}