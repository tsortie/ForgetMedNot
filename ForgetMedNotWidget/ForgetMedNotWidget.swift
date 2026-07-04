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
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        ZStack {
            
            // Text overlay
            VStack {
                HStack {
                    if entry.tookMedicine {
                        if let time = entry.medicineTime {
                            Text("Taken at\n\(time)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.black.opacity(0.85))
                                .padding(6)
                            .background(Color.black.opacity(0.15))
                                .cornerRadius(8)
                        }
                    } else {
                        Button(intent: TakeMedicineIntent()) {
                            Text("Log It")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.black.opacity(0.85))
                                .padding(6)
                            .background(Color.black.opacity(0.15))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                Spacer()
            }
            .padding(4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .ignoresSafeArea()
        }
        .containerBackground(for: .widget) {
            Image(entry.tookMedicine ? "scene_taken" : "scene_not_taken")
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
        .description("Track whether you've taken your medicine today.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
