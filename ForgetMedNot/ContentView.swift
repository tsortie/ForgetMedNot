import SwiftUI

struct iOSForgetMedNotView: View {
    @StateObject private var manager = MedicineManager()
    @Environment(\.scenePhase) var scenePhase
    @State private var showingHistory = false
    @State private var showingSettings = false
    @State private var showingClearConfirmation = false

    var body: some View {
        ZStack {
            Image(manager.tookMedicineToday ? "app_taken" : "app_not_taken")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()

            VStack(spacing: 40) {
                HStack {
                Spacer()
                    Button(action: { showingHistory = true }) {
                        Image(systemName: "calendar")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)

                ZStack {
                    VStack(spacing: 8) {
                        Image(systemName: manager.tookMedicineToday ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        if let time = manager.medicineTime {
                            Text("Taken at \n\(time)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.black.opacity(0.75))
                        }
                    }
                }

                Text(manager.tookMedicineToday ? "Medicine taken" : "Not logged yet")
                    .font(.body)
                    .foregroundColor(manager.tookMedicineToday ? .green : .orange)
                    .fontWeight(.medium)

                Spacer()

                if !manager.tookMedicineToday {
                    Button(action: { manager.recordMedicineTaken() }) {
                        Text("Log it")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                } else {
                    Button(action: { showingClearConfirmation = true }) {
                        Text("Clear Today's Log")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red.opacity(0.6))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .confirmationDialog(
                        "Are you sure you want to clear today's log?",
                        isPresented: $showingClearConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Clear Log", role: .destructive) {
                            manager.clearToday()
                        }
                        Button("Cancel", role: .cancel) {}
                    }
                }
            }
            .padding(30)
        }
        .sheet(isPresented: $showingHistory) {
            HistoryView(history: manager.history)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .onAppear {
            manager.loadTodayStatus()
            NotificationManager.shared.requestPermission()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                manager.loadTodayStatus()
            }
        }
    }
}
