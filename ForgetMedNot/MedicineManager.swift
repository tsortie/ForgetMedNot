import Foundation
import UIKit
import Combine
import WidgetKit

class MedicineManager: ObservableObject {
    @Published var tookMedicineToday = false
    @Published var medicineTime: String? = nil
    
    private let suite = UserDefaults(suiteName: "group.com.toddfeliciano.ForgetMedNot")!
    private let userDefaultsKey = "medicineTrackerDate"
    private let medicineTimeKey = "medicineTrackerTime"
    private var cancellables = Set<AnyCancellable>()
    let history = MedicineHistory()
    
    init() {
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
        suite.synchronize()
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
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        let formattedTime = timeFormatter.string(from: now)
        
        tookMedicineToday = true
        medicineTime = formattedTime
        
        suite.set(now, forKey: userDefaultsKey)
        suite.set(formattedTime, forKey: medicineTimeKey)
        suite.synchronize()
        
        history.recordTaken(at: formattedTime)
        
        NotificationManager.shared.cancelReminder()
        
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func clearToday() {
        tookMedicineToday = false
        medicineTime = nil
        
        suite.removeObject(forKey: userDefaultsKey)
        suite.removeObject(forKey: medicineTimeKey)
        suite.synchronize()
        
        history.clearToday()
        
        syncReminderState() // re-arms reminder since today is unlogged again
        
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func checkForMissedYesterday() {
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else { return }
        let yesterdayStatus = history.status(for: yesterday)
        
        // Only mark missed if no record exists — never overwrite a taken record
        if yesterdayStatus == .noData {
            // Check if the legacy UserDefaults date was yesterday
            let savedDate = suite.object(forKey: userDefaultsKey) as? Date
            if let savedDate = savedDate, calendar.isDate(savedDate, inSameDayAs: yesterday) {
                // Yesterday was actually recorded — write it to history
                let timeFormatter = DateFormatter()
                timeFormatter.timeStyle = .short
                let formattedTime = timeFormatter.string(from: savedDate)
                history.recordTaken(at: formattedTime)
            } else {
                history.recordMissed(for: yesterday)
            }
        }
    }
}
