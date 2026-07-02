import SwiftUI

struct HistoryView: View {
    @ObservedObject var history: MedicineHistory
    
    private var currentMonthDays: [(date: Date, status: DayStatus)] {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month], from: now)
        guard let firstOfMonth = calendar.date(from: components),
              let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count else {
            return []
        }
        
        var result: [(date: Date, status: DayStatus)] = []
        for i in 0..<daysInMonth {
            guard let date = calendar.date(byAdding: .day, value: i, to: firstOfMonth) else { continue }
            let status = history.status(for: date)
            let isFuture = calendar.compare(date, to: now, toGranularity: .day) == .orderedDescending
            let resolvedStatus: DayStatus
            if isFuture {
                resolvedStatus = .noData
            } else if calendar.isDateInToday(date) {
                resolvedStatus = status
            } else {
                resolvedStatus = status == .taken ? .taken : .missed
            }
            result.append((date: date, status: resolvedStatus))
        }
        return result
    }
    
    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }
    
    private var stats: (taken: Int, missed: Int) {
        let now = Date()
        let calendar = Calendar.current
        let pastDays = currentMonthDays.filter {
            calendar.compare($0.date, to: now, toGranularity: .day) != .orderedDescending
        }
        let taken = pastDays.filter { $0.status == .taken }.count
        let missed = pastDays.filter { $0.status == .missed }.count
        return (taken: taken, missed: missed)
    }
    
    private func paddedForSundayStart() -> [(date: Date, status: DayStatus)?] {
        guard let firstDate = currentMonthDays.first?.date else { return [] }
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: firstDate)
        let offset = weekday - 1
        var result: [(date: Date, status: DayStatus)?] = Array(repeating: nil, count: offset)
        result += currentMonthDays.map { Optional($0) }
        return result
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Stats
                let s = stats
                HStack(spacing: 16) {
                    StatCard(value: s.taken, label: "Taken", color: .green)
                    StatCard(value: s.missed, label: "Missed", color: .red)
                }
                .padding(.horizontal)
                
                // Weekday headers
                HStack {
                    ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                        Text(day)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                
                // Calendar grid
                let paddedDays = paddedForSundayStart()
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                    ForEach(0..<paddedDays.count, id: \.self) { i in
                        if let day = paddedDays[i] {
                            DayDot(date: day.date, status: day.status)
                        } else {
                            Color.clear.frame(width: 32, height: 44)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle(monthTitle)
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct StatCard: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct DayDot: View {
    let date: Date
    let status: DayStatus

    private var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var isFuture: Bool {
        Calendar.current.compare(date, to: Date(), toGranularity: .day) == .orderedDescending
    }

    private var dotColor: Color {
        if isFuture { return .gray.opacity(0.15) }
        switch status {
        case .taken: return .green
        case .missed: return .red
        case .noData: return .gray.opacity(0.3)
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(dotColor)
                .frame(width: 32, height: 32)
                .overlay(
                    Text(dayLabel)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(isFuture ? .gray.opacity(0.4) : (status == .noData ? .secondary : .white))
                )
        }
    }
}
