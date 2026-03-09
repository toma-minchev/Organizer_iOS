//
//  NotificationDelegate.swift
//  Organizer
//
//  Created by Toma Minchev on 9.03.26.
//

import ObjectiveC
import UserNotifications


class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
        @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
