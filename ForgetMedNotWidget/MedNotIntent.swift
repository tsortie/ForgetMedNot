import AppIntents
import Foundation
import WidgetKit

struct TakeMedicineIntent: AppIntent {
    static var title: LocalizedStringResource = "Record Medicine Taken"
    static var description = IntentDescription("Records that you took your medicine today.")
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    private static let dateKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        return formatter
    }()
    
    func perform() async throws -> some IntentResult {
        guard let suite = UserDefaults(suiteName: "group.com.toddfeliciano.ForgetMedNot") else {
            assertionFailure("Failed to open App Group suite 'group.com.toddfeliciano.ForgetMedNot' — check widget entitlements/App Group configuration.")
            return .result()
        }
        
        let now = Date()
        suite.set(now, forKey: "medicineTrackerDate")
        suite.set(Self.timeFormatter.string(from: now), forKey: "medicineTrackerTime")

        let historyKey = "medicineTrackerHistory"
        let todayKey = Self.dateKeyFormatter.string(from: now)

        var history = suite.dictionary(forKey: historyKey) as? [String: String] ?? [:]
        history[todayKey] = "taken"
        suite.set(history, forKey: historyKey)

        // Reschedule for tomorrow (not just cancel) so the reminder series
        // survives even if the app isn't opened for several days.
        let enabled = suite.bool(forKey: "notificationEnabled")
        let timeInterval = suite.double(forKey: "notificationTimeInterval")
        if enabled, timeInterval > 0 {
            let time = Date(timeIntervalSince1970: timeInterval)
            NotificationManager.shared.scheduleDailyReminder(at: time, skipToday: true)
        } else {
            NotificationManager.shared.cancelReminder()
        }

        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
