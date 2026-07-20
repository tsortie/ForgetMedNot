import Foundation
import UserNotifications

extension Notification.Name {
    static let openHistoryFromNotification = Notification.Name("openHistoryFromNotification")
}

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    private let summaryID = "forgetmednot.summary.reminder"

    private func doseNotificationID(_ index: Int) -> String {
        "forgetmednot.dose.\(index)"
    }

    func requestPermission() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    // Called when the user taps a delivered notification.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.notification.request.identifier == summaryID {
            NotificationCenter.default.post(name: .openHistoryFromNotification, object: nil)
        }
        completionHandler()
    }

    // Lets notifications still show a banner/sound even while the app is in the foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // MARK: - Per-Dose Reminders

    /// Schedules exactly one future occurrence for a specific dose index —
    /// today (if the time hasn't passed and skipToday is false) or tomorrow
    /// otherwise. Each dose has its own independent identifier so doses can
    /// be canceled/rescheduled without affecting the others.
    func scheduleDoseReminder(index: Int, at time: Date, skipToday: Bool, doseName: String) {
        cancelDoseReminder(index: index)

        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

        var targetDate = calendar.date(
            bySettingHour: timeComponents.hour ?? 9,
            minute: timeComponents.minute ?? 0,
            second: 0,
            of: Date()
        ) ?? Date()

        if skipToday || targetDate <= Date() {
            targetDate = calendar.date(byAdding: .day, value: 1, to: targetDate) ?? targetDate
        }

        let content = UNMutableNotificationContent()
        content.title = "Medicine Reminder"
        content.body = "Time to take your: \(doseName)"
        content.sound = .default

        let fireComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: targetDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: fireComponents, repeats: false)

        let request = UNNotificationRequest(identifier: doseNotificationID(index), content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling dose \(index) reminder: \(error)")
            }
        }
    }

    func cancelDoseReminder(index: Int) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [doseNotificationID(index)])
    }

    /// Cancels all dose reminder slots up to (but not including) the given
    /// count — used when notifications are disabled entirely, or a max
    /// dose count needs fully clearing.
    func cancelAllDoseReminders(upTo maxCount: Int) {
        let ids = (0..<maxCount).map { doseNotificationID($0) }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    private func doseBody(for index: Int) -> String {
        switch index {
        case 0: return "Don't forget your morning dose!"
        case 1: return "Time for your next dose."
        default: return "You have another dose to take today."
        }
    }

    // MARK: - Summary Notification

    func scheduleSummaryNotification(at date: Date, taken: Int, missed: Int, periodLabel: String) {
        cancelSummaryNotification()

        let content = UNMutableNotificationContent()
        content.title = "Your \(periodLabel) Summary"
        content.body = summaryBody(taken: taken, missed: missed)
        content.sound = .default

        let interval = max(date.timeIntervalSinceNow, 60)
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
