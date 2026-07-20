import Foundation
import UIKit
import Combine
import WidgetKit

class MedicineManager: ObservableObject {
    enum SummaryFrequency: String {
        case weekly
        case biweekly
        
        var days: Int {
            switch self {
            case .weekly: return 7
            case .biweekly: return 14
            }
        }
        
        var label: String {
            switch self {
            case .weekly: return "Weekly"
            case .biweekly: return "Biweekly"
            }
        }
    }

    @Published var takenCountToday = 0
    @Published var doseCount = 1 // current setting; 1...5
    @Published var lastDoseTime: String? = nil

    private let suite: UserDefaults
    private var cancellables = Set<AnyCancellable>()
    let history = MedicineHistory()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    // Keys for per-dose settings, shared with the widget via the App Group suite.
    private let doseCountKey = "doseCount"
    private func doseTimeKey(_ index: Int) -> String { "doseTime_\(index)" }
    private let lastDoseTimeKey = "medicineTrackerTime"

    var allTaken: Bool {
        takenCountToday >= doseCount
    }

    init() {
        if let appGroupSuite = UserDefaults(suiteName: "group.com.toddfeliciano.ForgetMedNot") {
            suite = appGroupSuite
        } else {
            assertionFailure("Failed to open App Group suite 'group.com.toddfeliciano.ForgetMedNot' — check entitlements/App Group configuration. Falling back to standard UserDefaults; widget will not see this data.")
            suite = .standard
        }

        loadTodayStatus()
        checkForMissedYesterday()

        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.loadTodayStatus()
                self?.checkForMissedYesterday()
            }
            .store(in: &cancellables)
    }

    // MARK: - Dose Count / Times Settings
    
    private func doseNameKey(_ index: Int) -> String { "doseName_\(index)" }

    func doseName(for index: Int) -> String {
        suite.string(forKey: doseNameKey(index)) ?? "Dose \(index + 1)"
    }

    func setDoseName(_ name: String, for index: Int) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            suite.removeObject(forKey: doseNameKey(index)) // falls back to "Dose N"
        } else {
            suite.set(trimmed, forKey: doseNameKey(index))
        }
    }

    func doseTime(for index: Int) -> Date {
        let stored = suite.double(forKey: doseTimeKey(index))
        if stored > 0 {
            return Date(timeIntervalSince1970: stored)
        }
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let defaultHours = [9, 13, 17, 20, 22]
        components.hour = defaultHours[min(index, defaultHours.count - 1)]
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    func setDoseTime(_ date: Date, for index: Int) {
        suite.set(date.timeIntervalSince1970, forKey: doseTimeKey(index))
        syncReminderState()
    }

    func setDoseCount(_ count: Int) {
        let clamped = max(1, min(5, count))
        suite.set(clamped, forKey: doseCountKey)
        doseCount = clamped
        loadTodayStatus()
    }

    // MARK: - Status

    func loadTodayStatus() {
        doseCount = suite.integer(forKey: doseCountKey) == 0 ? 1 : suite.integer(forKey: doseCountKey)

        if let record = history.record(for: Date()) {
            takenCountToday = record.takenCount
        } else {
            takenCountToday = 0
        }
        lastDoseTime = suite.string(forKey: lastDoseTimeKey)

        syncReminderState()
        syncSummaryNotificationState()
    }

    private func syncReminderState() {
        let enabled = suite.bool(forKey: "notificationEnabled")
        guard enabled else {
            NotificationManager.shared.cancelAllDoseReminders(upTo: 5)
            return
        }

        for index in 0..<doseCount {
            let time = doseTime(for: index)
            let alreadyTaken = index < takenCountToday
            NotificationManager.shared.scheduleDoseReminder(
                index: index,
                at: time,
                skipToday: alreadyTaken,
                doseName: doseName(for: index)
            )
        }
        if doseCount < 5 {
            for index in doseCount..<5 {
                NotificationManager.shared.cancelDoseReminder(index: index)
            }
        }
    }

    private func syncSummaryNotificationState() {
        let enabled = UserDefaults.standard.bool(forKey: "summaryEnabled")
        guard enabled else {
            NotificationManager.shared.cancelSummaryNotification()
            return
        }

        let nextDate = Self.nextSunday6PM()
        let stats = history.stats(forLastDays: 7)

        NotificationManager.shared.scheduleSummaryNotification(
            at: nextDate,
            taken: stats.taken,
            missed: stats.missed,
            periodLabel: "Weekly"
        )
    }

    /// Returns the next upcoming Sunday at 6:00 PM (today if it's Sunday and
    /// 6pm hasn't passed yet; otherwise the following Sunday).
    /// Returns the next upcoming Sunday at 6:00 PM (today if it's Sunday and
    /// 6pm hasn't passed yet; otherwise the following Sunday).
    static func nextSunday6PM(from now: Date = Date()) -> Date {
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: now) // 1 = Sunday
        let daysUntilSunday = (8 - currentWeekday) % 7

        guard let candidateDay = calendar.date(byAdding: .day, value: daysUntilSunday, to: now) else {
            return now
        }

        guard let candidate = calendar.date(
            bySettingHour: 18,
            minute: 0,
            second: 0,
            of: candidateDay
        ) else {
            return now
        }

        if candidate <= now {
            return calendar.date(byAdding: .day, value: 7, to: candidate) ?? candidate
        }

        return candidate
    }
    // MARK: - Logging

    func recordDoseTaken() {
        guard takenCountToday < doseCount else { return }

        let now = Date()
        let formattedTime = Self.timeFormatter.string(from: now)

        takenCountToday += 1
        lastDoseTime = formattedTime
        suite.set(formattedTime, forKey: lastDoseTimeKey)

        history.recordDoseTaken(doseCount: doseCount)

        syncReminderState()

        WidgetCenter.shared.reloadAllTimelines()
    }

    func undoLastDose() {
        guard takenCountToday > 0 else { return }
        takenCountToday -= 1
        history.undoLastDoseToday()
        syncReminderState()
        WidgetCenter.shared.reloadAllTimelines()
    }

    func clearToday() {
        takenCountToday = 0
        lastDoseTime = nil
        suite.removeObject(forKey: lastDoseTimeKey)

        history.clearToday()

        syncReminderState()

        WidgetCenter.shared.reloadAllTimelines()
    }

    private func checkForMissedYesterday() {
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else { return }
        history.recordMissed(for: yesterday, doseCount: doseCount)
    }
}
