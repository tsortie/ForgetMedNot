//
//  SettingsView.swift
//  ForgetMedNot
//
//  Created by Grace Haataja on 7/1/26.
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    @ObservedObject var manager: MedicineManager

    @AppStorage("notificationEnabled", store: UserDefaults(suiteName: "group.com.toddfeliciano.ForgetMedNot"))
    private var notificationEnabled = false

    @AppStorage("summaryEnabled") private var summaryEnabled = false

    @State private var doseTimes: [Date] = []
    @State private var doseNames: [String] = []

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Stepper(
                        "Logs per day: \(manager.doseCount)",
                        value: Binding(
                            get: { manager.doseCount },
                            set: { manager.setDoseCount($0) }
                        ),
                        in: 1...5
                    )

                    ForEach(0..<manager.doseCount, id: \.self) { index in
                        HStack {
                            TextField(
                                "Medication \(index + 1)",
                                text: Binding(
                                    get: { doseNames.indices.contains(index) ? doseNames[index] : manager.doseName(for: index) },
                                    set: { newName in
                                        if doseNames.indices.contains(index) {
                                            doseNames[index] = newName
                                        }
                                        manager.setDoseName(newName, for: index)
                                    }
                                )
                            )
                            .font(.subheadline)
                            .fontWeight(.medium)

                            DatePicker(
                                "Time",
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
                            .labelsHidden()
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section {
                    Toggle("Reminders", isOn: $notificationEnabled)
                        .onChange(of: notificationEnabled) { _, enabled in
                            if enabled {
                                NotificationManager.shared.requestPermission()
                            }
                            manager.loadTodayStatus()
                        }
                } header: {
                    Text("Notifications")
                } footer: {
                    if notificationEnabled {
                        if manager.allTaken {
                            Text("You've logged all of today's medications, so no more reminders will fire until tomorrow.")
                        } else {
                            Text("You'll be reminded for each medication you haven't logged yet, at the times set above.")
                        }
                    } else {
                        Text("Enable to receive reminders for each medication at the times set above.")
                    }
                }
         
// ----------- DEBUG FOR TEST SUMMARY NOTIFICATION --------
//Section {
//    Button("Send Test Summary Notification (5s)") {
//        let stats = manager.history.stats(forLastDays: 7)
//        let content = UNMutableNotificationContent()
//        content.title = "Your Weekly Summary"
//        content.body = "TEST: \(stats.taken) taken, \(stats.missed) missed"
//        content.sound = .default
//        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
//        let request = UNNotificationRequest(identifier: "forgetmednot.summary.reminder", content: content, trigger: trigger)
//        UNUserNotificationCenter.current().add(request) { error in
//            if let error = error {
//                print("Debug notification error: \(error)")
//            }
//        }
//    }
//} header: {
//    Text("Debug")
//}

                Section {
                    Toggle("Weekly Recap", isOn: $summaryEnabled)
                        .onChange(of: summaryEnabled) { _, enabled in
                            if !enabled {
                                NotificationManager.shared.cancelSummaryNotification()
                            }
                            manager.loadTodayStatus()
                        }
                } footer: {
                    if summaryEnabled {
                        Text("You'll get a summary of your previous week's logs every Sunday at 6:00 PM.")
                    } else {
                        Text("Get a weekly recap of your medicine-taking consistency, every Sunday at 6:00 PM.")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                doseTimes = (0..<5).map { manager.doseTime(for: $0) }
                doseNames = (0..<5).map { manager.doseName(for: $0) }
            }
        }
    }
}
