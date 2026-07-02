import Foundation
import Combine

class MedicineManager: ObservableObject {
    @Published var tookMedicineToday = false
    @Published var medicineTime: String? = nil

    private let suite = UserDefaults(suiteName: "group.com.toddfeliciano.ForgetMedNot")!
    private let userDefaultsKey = "medicineTrackerDate"
    private let medicineTimeKey = "medicineTrackerTime"
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadTodayStatus()
        
        NotificationCenter.default.publisher(for: Notification.Name("NSExtensionHostWillEnterForeground"))
            .sink { [weak self] _ in
                self?.loadTodayStatus()
            }
            .store(in: &cancellables)
    }

    func loadTodayStatus() {
        suite.synchronize()
        let savedDate = suite.object(forKey: userDefaultsKey) as? Date
        let savedTime = suite.string(forKey: medicineTimeKey)
        
        if let savedDate = savedDate, Calendar.current.isDateInToday(savedDate) {
            self.tookMedicineToday = true
            self.medicineTime = savedTime
        } else {
            self.tookMedicineToday = false
            self.medicineTime = nil
        }
    }

    func recordMedicineTaken() {
        let now = Date()
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        let formattedTime = timeFormatter.string(from: now)
        
        self.tookMedicineToday = true
        self.medicineTime = formattedTime
        
        suite.set(now, forKey: userDefaultsKey)
        suite.set(formattedTime, forKey: medicineTimeKey)
        suite.synchronize()
    }

    func clearToday() {
        self.tookMedicineToday = false
        self.medicineTime = nil
        suite.removeObject(forKey: userDefaultsKey)
        suite.removeObject(forKey: medicineTimeKey)
        suite.synchronize()
    }
}
