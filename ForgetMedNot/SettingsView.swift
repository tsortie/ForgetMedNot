//
//  SettingsView.swift
//  ForgetMedNot
//
//  Created by Grace Haataja on 7/1/26.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("summaryEnabled") private var summaryEnabled = false
    @AppStorage("summaryFrequency") private var summaryFrequencyRaw = MedicineManager.SummaryFrequency.weekly.rawValue
    @AppStorage("summaryAnchorInterval") private var summaryAnchorInterval: Double = 0

    @State private var summaryAnchorDate: Date = {
        let stored = UserDefaults.standard.double(forKey: "summaryAnchorInterval")
        if stored > 0 {
            return Date(timeIntervalSince1970: stored)
        }
        // Default: next Sunday at 6pm
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 18
        components.minute = 00
        let today = Calendar.current.date(from: components) ?? Date()
        let weekday = Calendar.current.component(.weekday, from: today)
        let daysUntilSunday = (8 - weekday) % 7
        return Calendar.current.date(byAdding: .day, value: daysUntilSunday, to: today) ?? today
    }()
    
    @ObservedObject var manager: MedicineManager
    
    @AppStorage("notificationEnabled") private var notificationEnabled = false
    @AppStorage("notificationTimeInterval") private var notificationTimeInterval: Double = Date().timeIntervalSince1970
    
    @State private var notificationTime: Date = {
        let stored = UserDefaults.standard.double(forKey: "notificationTimeInterval")
        if stored > 0 {
            return Date(timeIntervalSince1970: stored)
        }
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    // Ordered to match MTWRFSS layout logic
    private let weekdays = [
        (2, "Monday"), (3, "Tuesday"), (4, "Wednesday"),
        (5, "Thursday"), (6, "Friday"), (7, "Saturday"), (1, "Sunday")
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("Daily Reminder", isOn: $notificationEnabled)
                        .onChange(of: notificationEnabled) { _, enabled in
                            if enabled {
                                NotificationManager.shared.requestPermission()
                                scheduleIfNeeded()
                            } else {
                                NotificationManager.shared.cancelReminder()
                            }
                        }
                    
                    if notificationEnabled {
                        DatePicker(
                            "Remind me at",
                            selection: $notificationTime,
                            displayedComponents: .hourAndMinute
                        )
                        .onChange(of: notificationTime) { _, newTime in
                            notificationTimeInterval = newTime.timeIntervalSince1970
                            scheduleIfNeeded()
                        }
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    if notificationEnabled {
                        if manager.tookMedicineToday {
                            Text("You've already logged your medicine today, so no reminder will fire until tomorrow.")
                        } else {
                            Text("You'll receive a reminder at \(formattedTime) if you haven't recorded taking your medicine.")
                        }
                    } else {
                        Text("Enable to receive a daily reminder if you haven't recorded taking your medicine.")
                    }
                }
                Section {
                    Toggle("Progress Summary", isOn: $summaryEnabled)
                        .onChange(of: summaryEnabled) { _, enabled in
                            if enabled {
                                lockAnchorToNextSunday()
                            } else {
                                NotificationManager.shared.cancelSummaryNotification()
                            }
                        }
                    
                    if summaryEnabled {
                    }
                } header: {
                    Text("Progress Summary")
                } footer: {
                    if summaryEnabled {
                        Text("You'll get a summary every \(summaryFrequencyRaw == MedicineManager.SummaryFrequency.weekly.rawValue ? "week" : "two weeks") on Sunday at 6:00 PM.")
                    } else {
                        Text("Get a periodic recap of your medicine-taking consistency.")
                    }
                }

            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func scheduleIfNeeded() {
        if manager.tookMedicineToday {
            NotificationManager.shared.cancelReminder()
        } else {
            NotificationManager.shared.scheduleDailyReminder(at: notificationTime)
        }
    }
    
    private var formattedTime: String {
        Self.timeFormatter.string(from: notificationTime)
    }
    
    // MARK: - Date Mutators

    private func lockAnchorToNextSunday() {
        let calendar = Calendar.current
        
        // 1. Get today's date context stripped down to the calendar day
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 18
        components.minute = 00
        components.second = 0
        
        guard let todayWithTargetTime = calendar.date(from: components) else { return }
        
        // 2. Calculate the exact remaining days until the upcoming Sunday
        let currentWeekday = calendar.component(.weekday, from: todayWithTargetTime)
        let daysUntilSunday = (8 - currentWeekday) % 7
        
        // 3. Finalize the exact absolute date stamp object
        if let upcomingSunday = calendar.date(byAdding: .day, value: daysUntilSunday, to: todayWithTargetTime) {
            summaryAnchorDate = upcomingSunday
            summaryAnchorInterval = upcomingSunday.timeIntervalSince1970
            DispatchQueue.main.async {
                manager.loadTodayStatus()
            } // Sync downstream manager states
        }
    }

    private func updateTime(to newTime: Date) {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: newTime)
        
        if let updatedDate = calendar.date(bySettingHour: timeComponents.hour ?? 0,
            minute: timeComponents.minute ?? 0,
            second: 0,
            of: summaryAnchorDate) {
            summaryAnchorDate = updatedDate
            summaryAnchorInterval = updatedDate.timeIntervalSince1970
            manager.loadTodayStatus()
        }
    }
}
