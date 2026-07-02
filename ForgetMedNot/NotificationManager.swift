//
//  NotificationManager.swift
//  ForgetMedNot
//
//  Created by Grace Haataja on 7/1/26.
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    private let notificationID = "forgetmednot.daily.reminder"
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    func scheduleDailyReminder(at time: Date) {
        cancelReminder()
        
        let content = UNMutableNotificationContent()
        content.title = "Medicine Reminder"
        content.body = "Don't forget to take your medicine today!"
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: notificationID,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
    }
    
    func rescheduleAfterTaken(at time: Date) {
        cancelReminder()
        scheduleDailyReminder(at: time)
    }
}
