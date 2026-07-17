//
//  SettingsView.swift
//  ForgetMedNot
//
//  Created by Grace Haataja on 7/1/26.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var manager: MedicineManager

    @AppStorage("notificationEnabled", store: UserDefaults(suiteName: "group.com.toddfeliciano.ForgetMedNot"))
    private var notificationEnabled = false

    @AppStorage("summaryEnabled") private var summaryEnabled = false

    @State private var doseTimes: [Date] = []

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("Reminders", isOn: $notificationEnabled)
                        .onChange(of: notificationEnabled) { _, enabled in
                            if enabled {
                                NotificationManager.shared.requestPermission()
                            }
                            manager.loadTodayStatus() // triggers syncReminderState with new toggle value
                        }
                    
                    if notificationEnabled {
                        Stepper(
                            "Doses per day: \(manager.doseCount)",
                            value: Binding(
                                get: { manager.doseCount },
                                set: { manager.setDoseCount($0) }
                            ),
                            in: 1...5
                        )
                        
                        ForEach(0..<manager.doseCount, id: \.self) { index in
                            DatePicker(
                                doseLabel(for: index),
                                selection: Binding(
                                    get: { doseTimes.indices.contains(index) ? doseTimes[index] : manager.doseTime(for: index) },
                                    set: { newTime in
                                        if doseTimes.indices.contains(index) {
                                            doseTimes[index] = newTime
                                        }
                                        manager.setDoseTime(newTime, for: index)
                                    }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                        }
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    if notificationEnabled {
                        if manager.allTaken {
                            Text("You've logged all of today's doses, so no more reminders will fire until tomorrow.")
                        } else {
                            Text("You'll be reminded for each dose you haven't logged yet.")
                        }
                    } else {
                        Text("Enable to receive reminders for each dose throughout the day.")
                    }
                }
                
                Section {
                    Toggle("Progress Summary", isOn: $summaryEnabled)
                        .onChange(of: summaryEnabled) { _, enabled in
                            if !enabled {
                                NotificationManager.shared.cancelSummaryNotification()
                            }
                            manager.loadTodayStatus()
                        }
                } header: {
                    Text("Progress Summary")
                } footer: {
                    if summaryEnabled {
                        Text("You'll get a weekly summary of your progress every Sunday at 6:00 PM.")
                    } else {
                        Text("Get a weekly recap of your medicine-taking consistency, every Sunday at 6:00 PM.")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                doseTimes = (0..<5).map { manager.doseTime(for: $0) }
            }
        }
    }

    private func doseLabel(for index: Int) -> String {
        manager.doseCount == 1 ? "Remind me at" : "Dose \(index + 1) at"
    }
}
