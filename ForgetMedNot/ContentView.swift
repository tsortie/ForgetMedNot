import SwiftUI

struct iOSForgetMedNotView: View {
    @StateObject private var manager = MedicineManager()
    @Environment(\.scenePhase) var scenePhase
    @State private var showingHistory = false

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                HStack {
                    Text("ForgetMedNot")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                    Button(action: { showingHistory = true }) {
                        Image(systemName: "calendar")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)

                VStack(spacing: 12) {
                    Text("Did You Take Your Medicine?")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text("Today")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                ZStack {
                    Circle()
                        .fill(manager.tookMedicineToday ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 140, height: 140)
                        .shadow(color: manager.tookMedicineToday ? Color.green.opacity(0.5) : Color.clear, radius: 10)
                    VStack(spacing: 8) {
                        Image(systemName: manager.tookMedicineToday ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                        if let time = manager.medicineTime {
                            Text(time)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                }

                Text(manager.tookMedicineToday ? "Medicine taken" : "Not recorded yet")
                    .font(.body)
                    .foregroundColor(manager.tookMedicineToday ? .green : .orange)
                    .fontWeight(.medium)

                Spacer()

                if !manager.tookMedicineToday {
                    Button(action: { manager.recordMedicineTaken() }) {
                        Text("I Took My Medicine")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                } else {
                    Button(action: { manager.clearToday() }) {
                        Text("Clear Today's Record")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red.opacity(0.6))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
            }
            .padding(30)
        }
        .sheet(isPresented: $showingHistory) {
            HistoryView(history: manager.history)
        }
        .onAppear {
            manager.loadTodayStatus()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                manager.loadTodayStatus()
            }
        }
    }
}
