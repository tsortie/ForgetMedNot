//
//  MedicineHistory.swift
//  ForgetMedNot
//
//  Created by Grace Haataja on 7/1/26.
//

import Foundation

struct DayRecord: Codable {
    var takenCount: Int
    var doseCount: Int
}

class MedicineHistory: ObservableObject {
    private let suite: UserDefaults
    private let historyKey = "medicineTrackerHistoryV2"
    private let legacyHistoryKey = "medicineTrackerHistory"

    private static let dateKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        return formatter
    }()

    init() {
        if let appGroupSuite = UserDefaults(suiteName: "group.com.toddfeliciano.ForgetMedNot") {
            suite = appGroupSuite
        } else {
            assertionFailure("Failed to open App Group suite 'group.com.toddfeliciano.ForgetMedNot' — check entitlements/App Group configuration. Falling back to standard UserDefaults; widget will not see this data.")
            suite = .standard
        }
        migrateIfNeeded()
    }

    private func migrateIfNeeded() {
        guard suite.data(forKey: historyKey) == nil else { return }
        guard let oldRaw = suite.dictionary(forKey: legacyHistoryKey) as? [String: String] else { return }

        var migrated: [String: DayRecord] = [:]
        for (dateKey, status) in oldRaw {
            let takenCount = status == "taken" ? 1 : 0
            migrated[dateKey] = DayRecord(takenCount: takenCount, doseCount: 1)
        }
        saveHistory(migrated)
    }

    func loadHistory() -> [String: DayRecord] {
        guard let data = suite.data(forKey: historyKey),
              let decoded = try? JSONDecoder().decode([String: DayRecord].self, from: data) else {
            return [:]
        }
        return decoded
    }

    private func saveHistory(_ history: [String: DayRecord]) {
        guard let data = try? JSONEncoder().encode(history) else { return }
        suite.set(data, forKey: historyKey)
    }

    func recordDoseTaken(doseCount: Int) {
        var history = loadHistory()
        let key = dateKey(for: Date())
        var record = history[key] ?? DayRecord(takenCount: 0, doseCount: doseCount)
        record.doseCount = doseCount
        record.takenCount = min(record.takenCount + 1, doseCount)
        history[key] = record
        saveHistory(history)
        objectWillChange.send()
    }

    func recordMissed(for date: Date, doseCount: Int) {
        var history = loadHistory()
        let key = dateKey(for: date)
        if history[key] == nil {
            history[key] = DayRecord(takenCount: 0, doseCount: doseCount)
            saveHistory(history)
        }
    }

    func clearToday() {
        var history = loadHistory()
        history.removeValue(forKey: dateKey(for: Date()))
        saveHistory(history)
        objectWillChange.send()
    }

    func undoLastDoseToday() {
        var history = loadHistory()
        let key = dateKey(for: Date())
        guard var record = history[key], record.takenCount > 0 else { return }
        record.takenCount -= 1
        history[key] = record
        saveHistory(history)
        objectWillChange.send()
    }

    func record(for date: Date) -> DayRecord? {
        loadHistory()[dateKey(for: date)]
    }
    // MARK: - Rolling Stats (for summary notifications)

        /// The last `count` calendar days ending today (inclusive), oldest first.
        func lastDays(_ count: Int) -> [(date: Date, record: DayRecord?)] {
            let calendar = Calendar.current
            let today = Date()
            let allHistory = loadHistory()

            var result: [(date: Date, record: DayRecord?)] = []
            for offset in stride(from: count - 1, through: 0, by: -1) {
                guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
                let key = dateKey(for: date)
                result.append((date: date, record: allHistory[key]))
            }
            return result
        }

        /// A day counts as "taken" only if all doses were completed that day;
        /// anything else (partial or zero) counts as "missed" for this summary.
        func stats(forLastDays count: Int) -> (taken: Int, missed: Int) {
            let days = lastDays(count)
            var taken = 0
            var missed = 0
            for day in days {
                guard let record = day.record, record.doseCount > 0, record.takenCount >= record.doseCount else {
                    missed += 1
                    continue
                }
                taken += 1
            }
            return (taken: taken, missed: missed)
        }

    func dateKey(for date: Date) -> String {
        Self.dateKeyFormatter.string(from: date)
    }
}
