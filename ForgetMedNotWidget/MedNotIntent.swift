import AppIntents
import Foundation
import WidgetKit

struct TakeMedicineIntent: AppIntent {
    static var title: LocalizedStringResource = "Record Medicine Taken"
    static var description = IntentDescription("Records that you took your medicine today.")
    
    func perform() async throws -> some IntentResult {
        let suite = UserDefaults(suiteName: "group.com.toddfeliciano.ForgetMedNot")!
        let now = Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        suite.set(now, forKey: "medicineTrackerDate")
        suite.set(formatter.string(from: now), forKey: "medicineTrackerTime")

        // Also record in the history dictionary so HistoryView reflects
        // taps that originate from the widget (previously only the
        // legacy date/time keys were updated here).
        let historyKey = "medicineTrackerHistory"
        let dateKeyFormatter = DateFormatter()
        dateKeyFormatter.dateFormat = "MM-dd-yyyy"
        let todayKey = dateKeyFormatter.string(from: now)

        var history = suite.dictionary(forKey: historyKey) as? [String: String] ?? [:]
        history[todayKey] = "taken"
        suite.set(history, forKey: historyKey)

        suite.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
