import Foundation
import UIKit
import Combine
import WidgetKit

class MedicineManager: ObservableObject {
    @Published var tookMedicineToday = false
    @Published var medicineTime: String? = nil
    
    private let suite: UserDefaults
    private let userDefaultsKey = "medicineTrackerDate"
    private let medicineTimeKey = "medicineTrackerTime"
    private var cancellables = Set<AnyCancellable>()
    let history = MedicineHistory()
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
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
    
    func loadTodayStatus() {
        let savedDate = suite.object(forKey: userDefaultsKey) as? Date
        let savedTime = suite.string(forKey: medicineTimeKey)
        
        if let savedDate = savedDate, Calendar.current.isDateInToday(savedDate) {
            tookMedicineToday = true
            medicineTime = savedTime
        } else {
            tookMedicineToday = false
            medicineTime = nil
        }
        
        syncReminderState()
    }
    
    private func syncReminderState() {
        let enabled = UserDefaults.standard.bool(forKey: "notificationEnabled")
        let timeInterval = UserDefaults.standard.double(forKey: "notificationTimeInterval")
        
        guard enabled, timeInterval > 0 else {
            NotificationManager.shared.cancelReminder()
            return
        }
        
        if tookMedicineToday {
            NotificationManager.shared.cancelReminder()
        } else {
            let time = Date(timeIntervalSince1970: timeInterval)
            NotificationManager.shared.scheduleDailyReminder(at: time)
        }
    }
    
    func recordMedicineTaken() {
        let now = Date()
        let formattedTime = Self.timeFormatter.string(from: now)
        
        tookMedicineToday = true
        medicineTime = formattedTime
        
        suite.set(now, forKey: userDefaultsKey)
        suite.set(formattedTime, forKey: medicineTimeKey)
        
        history.recordTaken(at: formattedTime)
        
        syncReminderState()
        
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func clearToday() {
        tookMedicineToday = false
        medicineTime = nil
        
        suite.removeObject(forKey: userDefaultsKey)
        suite.removeObject(forKey: medicineTimeKey)
        
        history.clearToday()
        
        syncReminderState() // re-arms reminder since today is unlogged again
        
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func checkForMissedYesterday() {
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else { return }
        let yesterdayStatus = history.status(for: yesterday)
        
        // Only mark missed if no record exists — never overwrite a taken record
        guard yesterdayStatus == .noData else { return }
        
        let savedDate = suite.object(forKey: userDefaultsKey) as? Date
        if let savedDate = savedDate, calendar.isDate(savedDate, inSameDayAs: yesterday) {
            // Yesterday was actually recorded — write it to history
            let formattedTime = Self.timeFormatter.string(from: savedDate)
            history.recordTaken(at: formattedTime)
        } else {
            history.recordMissed(for: yesterday)
        }
    }
}
