import SwiftUI

struct ProgressRing: View {
    let takenCount: Int
    let doseCount: Int

    private var progress: CGFloat {
        doseCount > 0 ? CGFloat(takenCount) / CGFloat(doseCount) : 0
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.black.opacity(0.15), lineWidth: 10)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.green, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: takenCount)

            VStack(spacing: 2) {
                Text("\(takenCount)/\(doseCount)")
                    .font(.title2)
                    .foregroundColor(.black.opacity(0.8))
                Text(doseCount == 1 ? "Medication" : "Medications")
                    .font(.caption2)
                    .foregroundColor(.black.opacity(0.6))
            }
        }
        .frame(width: 120, height: 120)
    }
}

struct iOSForgetMedNotView: View {
    @StateObject private var manager = MedicineManager()
    @Environment(\.scenePhase) var scenePhase
    @State private var showingHistory = false
    @State private var showingSettings = false
    @State private var showingClearConfirmation = false

    private let backgroundSourceSize = CGSize(width: 1024, height: 1024)
    private let mugSourcePoint = CGPoint(x: 585, y: 535)
    
    var body: some View {
        ZStack {
            Image(manager.allTaken ? "app_taken" : "app_not_taken")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()
                .ignoresSafeArea(.keyboard)
            
            GeometryReader { geo in
                let mugPos = fillPosition(
                    sourceSize: backgroundSourceSize,
                    containerSize: geo.size,
                    sourcePoint: mugSourcePoint
                )
                SteamAnimationView(mugCenterX: mugPos.x, mugCenterY: mugPos.y)
            }
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

                ProgressRing(takenCount: manager.takenCountToday, doseCount: manager.doseCount)

                if let time = manager.lastDoseTime {
                    Text(manager.allTaken ? "All medications taken! \nLast logged at \(time)" : "Last logged at \(time)")
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.75))
                        .fontWeight(.bold)
                        .lineLimit(2)
                } else {
                    Text("Not logged yet")
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.75))
                        .fontWeight(.bold)
                }

                Spacer()

                VStack(spacing: 12) {
                    if !manager.allTaken {
                        Button(action: { manager.recordDoseTaken() }) {
                            Text(manager.doseCount == 1 ? "Log it" : "Log \(manager.doseName(for: manager.takenCountToday))")
                                .font(.caption)
                                .frame(maxWidth: 220)
                                .padding(.vertical, 10)
                                .background(Color.black.opacity(0.4))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .fontWeight(.bold)
                        }
                    }

                    if manager.takenCountToday > 0 {
                        Button(action: {
                            if manager.takenCountToday == manager.doseCount {
                                showingClearConfirmation = true
                            } else {
                                manager.undoLastDose()
                            }
                        }) {
                            Text(manager.allTaken ? "Clear Today's Log" : "Undo Last Log")
                                .font(.caption)
                                .frame(maxWidth: 220)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.5))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .fontWeight(.bold)
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
            }
            .padding(30)
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showingHistory) {
            HistoryView(history: manager.history)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(manager: manager)
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
        .onReceive(NotificationCenter.default.publisher(for: .openHistoryFromNotification)) { _ in
            showingHistory = true
        }
    }
}

func fillPosition(sourceSize: CGSize, containerSize: CGSize, sourcePoint: CGPoint) -> CGPoint {
    let scale = max(containerSize.width / sourceSize.width, containerSize.height / sourceSize.height)
    let scaledWidth = sourceSize.width * scale
    let scaledHeight = sourceSize.height * scale
    let offsetX = (scaledWidth - containerSize.width) / 2
    let offsetY = (scaledHeight - containerSize.height) / 2
    return CGPoint(
        x: sourcePoint.x * scale - offsetX,
        y: sourcePoint.y * scale - offsetY
    )
}
