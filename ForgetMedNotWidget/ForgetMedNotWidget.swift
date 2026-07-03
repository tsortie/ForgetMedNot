import WidgetKit
import SwiftUI
import AppIntents

struct MedicineEntry: TimelineEntry {
    let date: Date
    let tookMedicine: Bool
    let medicineTime: String?
}

struct MedicineProvider: TimelineProvider {
    let suite = UserDefaults(suiteName: "group.com.toddfeliciano.ForgetMedNot")!

    func placeholder(in context: Context) -> MedicineEntry {
        MedicineEntry(date: Date(), tookMedicine: false, medicineTime: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (MedicineEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MedicineEntry>) -> Void) {
        // Refresh at midnight to auto-reset
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.day! += 1
        let midnight = Calendar.current.date(from: components)!
        let timeline = Timeline(entries: [currentEntry()], policy: .after(midnight))
        completion(timeline)
    }

    private func currentEntry() -> MedicineEntry {
        let savedDate = suite.object(forKey: "medicineTrackerDate") as? Date
        let savedTime = suite.string(forKey: "medicineTrackerTime")
        let tookToday = savedDate.map { Calendar.current.isDateInToday($0) } ?? false
        return MedicineEntry(
            date: Date(),
            tookMedicine: tookToday,
            medicineTime: tookToday ? savedTime : nil
        )
    }
}

struct ForgetMedNotWidgetView: View {
    var entry: MedicineEntry

    var body: some View {
        VStack(spacing: 6) {
            if entry.tookMedicine {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.green)
                if let time = entry.medicineTime {
                    Text("Taken at " + time)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            } else {
                Button(intent: TakeMedicineIntent()) {
                    VStack(spacing: 4) {
                        Image(systemName: "pill.circle")
                            .font(.system(size: 32))
                            .foregroundColor(.blue)
                        Text("Log it")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .containerBackground(.background, for: .widget)
    }
}

struct ForgetMedNotWidget: Widget {
    let kind: String = "ForgetMedNotWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MedicineProvider()) { entry in
            ForgetMedNotWidgetView(entry: entry)
        }
        .configurationDisplayName("Medicine Tracker")
        .description("Track whether you've taken your medicine today.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
