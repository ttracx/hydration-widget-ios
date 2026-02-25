import WidgetKit
import SwiftUI

struct HydrationProvider: TimelineProvider {
    func placeholder(in context: Context) -> HydrationEntry {
        HydrationEntry(date: Date(), todayOz: 32, goalOz: 64)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (HydrationEntry) -> ()) {
        let (today, goal) = loadHydration()
        let entry = HydrationEntry(date: Date(), todayOz: today, goalOz: goal)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let (today, goal) = loadHydration()
        let currentDate = Date()
        
        var entries: [HydrationEntry] = []
        for minuteOffset in stride(from: 0, to: 60, by: 15) {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            entries.append(HydrationEntry(date: entryDate, todayOz: today, goalOz: goal))
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    private func loadHydration() -> (Int, Int) {
        let defaults = UserDefaults(suiteName: "group.com.yourname.hydrationwidget")
        
        // Check if data is from today
        let lastDate = defaults?.object(forKey: "lastLogDate") as? Date ?? Date.distantPast
        if !Calendar.current.isDateInToday(lastDate) {
            return (0, 64)
        }
        
        if let data = defaults?.data(forKey: "waterLogs"),
           let logs = try? JSONDecoder().decode([WaterLog].self, from: data) {
            let today = logs.reduce(0) { $0 + $1.amount }
            return (today, 64)
        }
        return (0, 64)
    }
}

struct WaterLog: Codable {
    let id = UUID()
    let amount: Int
    let time: Date
}

struct HydrationEntry: TimelineEntry {
    let date: Date
    let todayOz: Int
    let goalOz: Int
}

struct HydrationWidgetEntryView : View {
    var entry: HydrationProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var progress: CGFloat {
        min(CGFloat(entry.todayOz) / CGFloat(entry.goalOz), 1.0)
    }
    
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color.cyan.gradient)
            
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundColor(.white)
                    Text("\(entry.todayOz) oz")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white)
                            .frame(width: geo.size.width * progress, height: 8)
                    }
                }
                .frame(height: 8)
                .padding(.horizontal, 8)
                
                Text("Goal: \(entry.goalOz) oz")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
        }
    }
}

@main
struct HydrationWidget: Widget {
    let kind: String = "HydrationWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HydrationProvider()) { entry in
            HydrationWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Hydration Tracker")
        .description("Track daily water intake")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
