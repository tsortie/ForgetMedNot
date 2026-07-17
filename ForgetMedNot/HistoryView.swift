import SwiftUI

struct PieSlice: Shape {
    var progress: CGFloat // 0...1

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let startAngle = Angle(degrees: -90) // start at top
        let endAngle = Angle(degrees: -90 + (360 * Double(progress)))

        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.closeSubpath()
        return path
    }
}

struct HistoryView: View {
    @ObservedObject var history: MedicineHistory
    
    private static let monthTitleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    private func buildCurrentMonthDays() -> [(date: Date, record: DayRecord?)] {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month], from: now)
        guard let firstOfMonth = calendar.date(from: components),
              let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count else {
            return []
        }
        
        let allHistory = history.loadHistory()
        
        var result: [(date: Date, record: DayRecord?)] = []
        for i in 0..<daysInMonth {
            guard let date = calendar.date(byAdding: .day, value: i, to: firstOfMonth) else { continue }
            let isFuture = calendar.compare(date, to: now, toGranularity: .day) == .orderedDescending
            
            if isFuture {
                result.append((date: date, record: nil))
                continue
            }
            
            let key = history.dateKey(for: date)
            result.append((date: date, record: allHistory[key]))
        }
        return result
    }
    
    private var monthTitle: String {
        Self.monthTitleFormatter.string(from: Date())
    }
    
    private func stats(for days: [(date: Date, record: DayRecord?)]) -> (full: Int, partial: Int, missed: Int) {
        let now = Date()
        let calendar = Calendar.current
        let pastDays = days.filter {
            calendar.compare($0.date, to: now, toGranularity: .day) != .orderedDescending
        }
        
        var full = 0, partial = 0, missed = 0
        for day in pastDays {
            guard let record = day.record, record.doseCount > 0 else {
                missed += 1
                continue
            }
            if record.takenCount >= record.doseCount {
                full += 1
            } else if record.takenCount > 0 {
                partial += 1
            } else {
                missed += 1
            }
        }
        return (full: full, partial: partial, missed: missed)
    }
    
    private func paddedForSundayStart(_ days: [(date: Date, record: DayRecord?)]) -> [(date: Date, record: DayRecord?)?] {
        guard let firstDate = days.first?.date else { return [] }
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: firstDate)
        let offset = weekday - 1
        var result: [(date: Date, record: DayRecord?)?] = Array(repeating: nil, count: offset)
        result += days.map { Optional($0) }
        return result
    }
    
    var body: some View {
        let currentMonthDays = buildCurrentMonthDays()
        let s = stats(for: currentMonthDays)
        let paddedDays = paddedForSundayStart(currentMonthDays)
        
        NavigationView {
            VStack(spacing: 24) {
                HStack(spacing: 12) {
                    StatCard(value: s.full, label: "Full Days", color: .green)
                    StatCard(value: s.partial, label: "Partial", color: .orange)
                    StatCard(value: s.missed, label: "Missed", color: .red)
                }
                .padding(.horizontal)
                
                HStack {
                    ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                        Text(day)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                    ForEach(0..<paddedDays.count, id: \.self) { i in
                        if let day = paddedDays[i] {
                            DayDot(date: day.date, record: day.record)
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
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct DayDot: View {
    let date: Date
    let record: DayRecord?
    
    private static let dayLabelFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()

    private var dayLabel: String {
        Self.dayLabelFormatter.string(from: date)
    }

    private var isFuture: Bool {
        Calendar.current.compare(date, to: Date(), toGranularity: .day) == .orderedDescending
    }
    
    private var progress: CGFloat {
        guard let record = record, record.doseCount > 0 else { return 0 }
        return CGFloat(record.takenCount) / CGFloat(record.doseCount)
    }
    
    private var isFullyTaken: Bool {
        guard let record = record, record.doseCount > 0 else { return false }
        return record.takenCount >= record.doseCount
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(isFuture ? Color.gray.opacity(0.1) : Color.gray.opacity(0.15))
                .frame(width: 32, height: 32)
            
            if !isFuture {
                if isFullyTaken {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 32, height: 32)
                } else {
                    // 0 doses through n-1 doses: red pie fill proportional to progress.
                    // At progress == 0 this renders as no visible fill (just the base gray circle).
                    PieSlice(progress: progress)
                        .fill(Color.red.opacity(0.75))
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                }
            }
            
            Text(dayLabel)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(isFuture ? .gray.opacity(0.4) : (isFullyTaken ? .white : .primary))
        }
    }
}
