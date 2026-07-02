//
//  SettingsView.swift
//  ForgetMedNot
//
//  Created by Grace Haataja on 7/1/26.
//

import SwiftUI

struct SettingsView: View {
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
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("Daily Reminder", isOn: $notificationEnabled)
                        .onChange(of: notificationEnabled) { _, enabled in
                            if enabled {
                                NotificationManager.shared.requestPermission()
                                NotificationManager.shared.scheduleDailyReminder(at: notificationTime)
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
                            NotificationManager.shared.scheduleDailyReminder(at: newTime)
                        }
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    if notificationEnabled {
                        Text("You'll receive a reminder at \(formattedTime) if you haven't recorded taking your medicine.")
                    } else {
                        Text("Enable to receive a daily reminder if you haven't recorded taking your medicine.")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: notificationTime)
    }
}
