import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    private let notificationID = "forgetmednot.daily.reminder"
    private let summaryID = "forgetmednot.summary.reminder"
    
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
        
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
    }
    
    // MARK: - Summary Notification
    
    func scheduleSummaryNotification(at date: Date, taken: Int, missed: Int, periodLabel: String) {
        cancelSummaryNotification()
        
        let content = UNMutableNotificationContent()
        content.title = "Your \(periodLabel) Summary"
        content.body = summaryBody(taken: taken, missed: missed)
        content.sound = .default
        
        let interval = max(date.timeIntervalSinceNow, 60) // must be > 0
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        
        let request = UNNotificationRequest(identifier: summaryID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling summary notification: \(error)")
            }
        }
    }
    
    func cancelSummaryNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [summaryID])
    }
    
    private func summaryBody(taken: Int, missed: Int) -> String {
        let total = taken + missed
        guard total > 0 else {
            return "No data logged yet — start tracking to see your progress here."
        }
        let percentage = Int((Double(taken) / Double(total)) * 100)
        return "You took your medicine \(taken) of \(total) days (\(percentage)%). Missed: \(missed)."
    }
}
