//
//  MedicineHistory.swift
//  ForgetMedNot
//
//  Created by Grace Haataja on 7/1/26.
//

import Foundation

// MARK: - Day Status
enum DayStatus: String, Codable {
    case taken
    case missed
    case noData
}

// MARK: - Medicine History Manager
class MedicineHistory: ObservableObject {
    private let suite: UserDefaults
    private let historyKey = "medicineTrackerHistory"

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
    }

    func loadHistory() -> [String: DayStatus] {
        guard let raw = suite.dictionary(forKey: historyKey) as? [String: String] else {
            return [:]
        }
        var result: [String: DayStatus] = [:]
        for (key, value) in raw {
            result[key] = DayStatus(rawValue: value) ?? .noData
        }
        return result
    }

    func recordTaken(at time: String) {
        var history = loadRaw()
        history[dateKey(for: Date())] = DayStatus.taken.rawValue
        suite.set(history, forKey: historyKey)
        objectWillChange.send()
    }

    func recordMissed(for date: Date) {
        var history = loadRaw()
        let key = dateKey(for: date)
        if history[key] == nil {
            history[key] = DayStatus.missed.rawValue
            suite.set(history, forKey: historyKey)
        }
    }

    func clearToday() {
        var history = loadRaw()
        history.removeValue(forKey: dateKey(for: Date()))
        suite.set(history, forKey: historyKey)
        objectWillChange.send()
    }

    func status(for date: Date) -> DayStatus {
        let history = loadHistory()
        return history[dateKey(for: date)] ?? .noData
    }

    func lastDays(_ count: Int) -> [(date: Date, status: DayStatus)] {
        let history = loadHistory()
        let calendar = Calendar.current
        var result: [(date: Date, status: DayStatus)] = []

        // Find the most recent Sunday on or before today
        let today = Date()
        let todayWeekday = calendar.component(.weekday, from: today) // 1 = Sunday
        let daysSinceSunday = todayWeekday - 1
        guard let mostRecentSunday = calendar.date(byAdding: .day, value: -daysSinceSunday, to: today) else { return [] }

        // Start from that Sunday and go forward count days
        for i in 0..<count {
            guard let date = calendar.date(byAdding: .day, value: i, to: mostRecentSunday) else { continue }
            let key = dateKey(for: date)

            let status: DayStatus
            if calendar.isDateInToday(date) || date < today {
                // Past or today — use real status
                if calendar.isDateInToday(date) {
                    status = history[key] ?? .noData
                } else {
                    status = history[key] ?? .missed
                }
            } else {
                // Future — show as noData (greyed out)
                status = .noData
            }

            result.append((date: date, status: status))
        }

        return result
    }

    func stats(forLastDays count: Int) -> (taken: Int, missed: Int, noData: Int) {
        let days = lastDays(count)
        let taken = days.filter { $0.status == .taken }.count
        let missed = days.filter { $0.status == .missed }.count
        let noData = days.filter { $0.status == .noData }.count
        return (taken: taken, missed: missed, noData: noData)
    }

    private func loadRaw() -> [String: String] {
        return suite.dictionary(forKey: historyKey) as? [String: String] ?? [:]
    }

    func dateKey(for date: Date) -> String {
        return Self.dateKeyFormatter.string(from: date)
    }
}
