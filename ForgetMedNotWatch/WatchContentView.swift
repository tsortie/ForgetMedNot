import SwiftUI

struct WatchContentView: View {
    @StateObject private var manager = MedicineManager()
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 12) {
                Text("Medicine")
                    .font(.headline)
                    .foregroundColor(.white)

                ZStack {
                    Circle()
                        .fill(manager.tookMedicineToday ? Color.green : Color.gray.opacity(0.5))
                        .frame(width: 80, height: 80)
                    VStack(spacing: 4) {
                        Image(systemName: manager.tookMedicineToday ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                        if let time = manager.medicineTime {
                            Text(time)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                }

                Text(manager.tookMedicineToday ? "Taken" : "Not yet")
                    .font(.caption)
                    .foregroundColor(manager.tookMedicineToday ? .green : .orange)
                    .fontWeight(.semibold)

                Spacer()

                if !manager.tookMedicineToday {
                    Button(action: { manager.recordMedicineTaken() }) {
                        Text("Took It")
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                } else {
                    Text("Recorded")
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                }
            }
            .padding(12)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { manager.loadTodayStatus() }
        }
    }
}
