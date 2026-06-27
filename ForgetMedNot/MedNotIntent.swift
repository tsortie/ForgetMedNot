import AppIntents
import Foundation

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
        return .result()
    }
}
