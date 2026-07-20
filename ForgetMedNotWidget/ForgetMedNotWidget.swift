import WidgetKit
import SwiftUI

struct MedicineEntry: TimelineEntry {
    let date: Date
    let takenCount: Int
    let doseCount: Int
    let lastDoseTime: String?
    let nextDoseName: String
}

struct MedicineProvider: TimelineProvider {
    private var suite: UserDefaults {
        UserDefaults(suiteName: "group.com.toddfeliciano.ForgetMedNot") ?? .standard
    }

    func placeholder(in context: Context) -> MedicineEntry {
        MedicineEntry(date: Date(), takenCount: 0, doseCount: 1, lastDoseTime: nil, nextDoseName: "Dose 1")
    }

    func getSnapshot(in context: Context, completion: @escaping (MedicineEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MedicineEntry>) -> Void) {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.day! += 1

        guard let midnight = Calendar.current.date(from: components) else {
            let timeline = Timeline(entries: [currentEntry()], policy: .after(Date().addingTimeInterval(3600)))
            completion(timeline)
            return
        }

        let timeline = Timeline(entries: [currentEntry()], policy: .after(midnight))
        completion(timeline)
    }

    private func currentEntry() -> MedicineEntry {
        let doseCount = suite.integer(forKey: "doseCount") == 0 ? 1 : suite.integer(forKey: "doseCount")
        let history = MedicineHistory()
        let record = history.record(for: Date())
        let takenCount = record?.takenCount ?? 0
        let lastTime = suite.string(forKey: "medicineTrackerTime")

        let nextIndex = min(takenCount, doseCount - 1)
        let nextName = suite.string(forKey: "doseName_\(nextIndex)") ?? "Medication \(nextIndex + 1)"

        return MedicineEntry(
            date: Date(),
            takenCount: takenCount,
            doseCount: doseCount,
            lastDoseTime: takenCount > 0 ? lastTime : nil,
            nextDoseName: nextName
        )
    }
}

struct WidgetProgressRing: View {
    let takenCount: Int
    let doseCount: Int

    private var progress: CGFloat {
        doseCount > 0 ? CGFloat(takenCount) / CGFloat(doseCount) : 0
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.35), lineWidth: 5)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.green, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text("\(takenCount)/\(doseCount)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.black.opacity(0.8))
        }
    }
}

struct ForgetMedNotWidgetView: View {
    var entry: MedicineEntry
    @Environment(\.widgetFamily) var widgetFamily

    private var allTaken: Bool {
        entry.takenCount >= entry.doseCount
    }

    var body: some View {
        VStack {
            HStack {
                if !allTaken {
                    Button(intent: TakeMedicineIntent()) {
                        Text("Log \(entry.nextDoseName)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.black.opacity(0.40))
                            .cornerRadius(8)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("All meds logged!")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(6)
                        .cornerRadius(8)
                }
                Spacer ()
                
                WidgetProgressRing(takenCount: entry.takenCount, doseCount: entry.doseCount)
                    .frame(width: 36, height: 36)
            }
            Spacer()
        }
        .padding(4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) {
            Image(allTaken ? "scene_taken" : "scene_not_taken")
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
    }
}

struct ForgetMedNotWidget: Widget {
    let kind: String = "ForgetMedNotWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MedicineProvider()) { entry in
            ForgetMedNotWidgetView(entry: entry)
        }
        .configurationDisplayName("Medicine Tracker")
        .description("Track your daily medicine doses.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
