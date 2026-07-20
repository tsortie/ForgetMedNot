import AppIntents
import Foundation
import WidgetKit

struct TakeMedicineIntent: AppIntent {
    static var title: LocalizedStringResource = "Record Medicine Taken"
    static var description = IntentDescription("Records that you took a dose of your medicine.")

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    func perform() async throws -> some IntentResult {
        guard let suite = UserDefaults(suiteName: "group.com.toddfeliciano.ForgetMedNot") else {
            assertionFailure("Failed to open App Group suite 'group.com.toddfeliciano.ForgetMedNot' — check widget entitlements/App Group configuration.")
            return .result()
        }

        let doseCount = suite.integer(forKey: "doseCount") == 0 ? 1 : suite.integer(forKey: "doseCount")

        let history = MedicineHistory()
        let existingRecord = history.record(for: Date())
        let takenCountBefore = existingRecord?.takenCount ?? 0

        guard takenCountBefore < doseCount else {
            return .result()
        }

        let now = Date()
        history.recordDoseTaken(doseCount: doseCount)
        suite.set(Self.timeFormatter.string(from: now), forKey: "medicineTrackerTime")

        let takenCountAfter = takenCountBefore + 1

        let enabled = suite.bool(forKey: "notificationEnabled")
        if enabled {
            for index in 0..<doseCount {
                let alreadyTaken = index < takenCountAfter
                let time = doseTime(from: suite, index: index)
                let name = doseName(from: suite, index: index)
                NotificationManager.shared.scheduleDoseReminder(index: index, at: time, skipToday: alreadyTaken, doseName: name)
            }
        } else {
            NotificationManager.shared.cancelAllDoseReminders(upTo: 5)
        }

        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }

    private func doseTime(from suite: UserDefaults, index: Int) -> Date {
        let stored = suite.double(forKey: "doseTime_\(index)")
        if stored > 0 {
            return Date(timeIntervalSince1970: stored)
        }
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let defaultHours = [9, 13, 17, 20, 22]
        components.hour = defaultHours[min(index, defaultHours.count - 1)]
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }
    
    private func doseName(from suite: UserDefaults, index: Int) -> String {
        suite.string(forKey: "doseName_\(index)") ?? "Dose \(index + 1)"
    }
}
