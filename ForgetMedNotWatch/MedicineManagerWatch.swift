import Foundation
import Combine

class MedicineManager: ObservableObject {
    @Published var tookMedicineToday = false
    @Published var medicineTime: String? = nil

    private let suite = UserDefaults(suiteName: "group.com.toddfeliciano.ForgetMedNot")!
    private let userDefaultsKey = "medicineTrackerDate"
    private let medicineTimeKey = "medicineTrackerTime"

    init() {
        loadTodayStatus()
    }

    func loadTodayStatus() {
        let savedDate = suite.object(forKey: userDefaultsKey) as? Date
        let savedTime = suite.string(forKey: medicineTimeKey)
        DispatchQueue.main.async {
            if let savedDate = savedDate, Calendar.current.isDateInToday(savedDate) {
                self.tookMedicineToday = true
                self.medicineTime = savedTime
            } else {
                self.tookMedicineToday = false
                self.medicineTime = nil
            }
        }
    }

    func recordMedicineTaken() {
        let now = Date()
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        let formattedTime = timeFormatter.string(from: now)
        DispatchQueue.main.async {
            self.tookMedicineToday = true
            self.medicineTime = formattedTime
        }
        suite.set(now, forKey: userDefaultsKey)
        suite.set(formattedTime, forKey: medicineTimeKey)
    }

    func clearToday() {
        DispatchQueue.main.async {
            self.tookMedicineToday = false
            self.medicineTime = nil
        }
        suite.removeObject(forKey: userDefaultsKey)
        suite.removeObject(forKey: medicineTimeKey)
    }
}
