//
//  HistoryView.swift
//  ForgetMedNot
//
//  Created by Grace Haataja on 7/1/26.
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject var history: MedicineHistory
    @State private var selectedRange = 7
    
    private func paddedForSundayStart(days: [(date: Date, status: DayStatus)]) -> [(date: Date, status: DayStatus)?] {
        guard let firstDate = days.first?.date else { return [] }
        let calendar = Calendar.current
        // Sunday = 1 in Calendar, so offset = weekday - 1
        let weekday = calendar.component(.weekday, from: firstDate)
        let offset = weekday - 1
        var result: [(date: Date, status: DayStatus)?] = Array(repeating: nil, count: offset)
        result += days.map { Optional($0) }
        return result
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Picker("Range", selection: $selectedRange) {
                    Text("7 Days").tag(7)
                    Text("14 Days").tag(14)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                let stats = history.stats(forLastDays: selectedRange)
                HStack(spacing: 16) {
                    StatCard(value: stats.taken, label: "Taken", color: .green)
                    StatCard(value: stats.missed, label: "Missed", color: .red)
                    StatCard(value: selectedRange - stats.taken - stats.missed, label: "No Data", color: .gray)
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Daily Log")
                        .font(.headline)
                        .padding(.horizontal)

                    let days = history.lastDays(selectedRange)
                    let paddedDays = paddedForSundayStart(days: days)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                        ForEach(0..<paddedDays.count, id: \.self) { i in
                            if let day = paddedDays[i] {
                                DayDot(date: day.date, status: day.status)
                            } else {
                                Color.clear
                                    .frame(width: 32, height: 44)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.top)
            .navigationTitle("History")
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

    private var weekdayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private var isFuture: Bool {
        Calendar.current.compare(date, to: Date(), toGranularity: .day) == .orderedDescending
    }

    private var dotColor: Color {
        if isFuture {
            return .gray.opacity(0.15)
        }
        switch status {
        case .taken: return .green
        case .missed: return .red
        case .noData: return .gray.opacity(0.3)
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(weekdayLabel)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
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
