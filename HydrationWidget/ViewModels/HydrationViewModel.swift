import SwiftUI
import WidgetKit

struct WaterLog: Identifiable, Codable {
    let id = UUID()
    let amount: Int
    let time: Date
}

class HydrationViewModel: ObservableObject {
    @Published var todayOz: Int = 0
    @Published var goalOz: Int = 64
    @Published var logs: [WaterLog] = []
    @Published var isPro = false
    
    private let defaults = UserDefaults(suiteName: "group.com.yourname.hydrationwidget")
    private let logsKey = "waterLogs"
    private let lastDateKey = "lastLogDate"
    private let proKey = "isProUser"
    
    init() {
        isPro = defaults?.bool(forKey: proKey) ?? false
        loadLogs()
        
        // Reset if new day
        let lastDate = defaults?.object(forKey: lastDateKey) as? Date ?? Date.distantPast
        if !Calendar.current.isDateInToday(lastDate) {
            logs = []
            todayOz = 0
        }
    }
    
    func addWater(_ amount: Int) {
        let log = WaterLog(amount: amount, time: Date())
        logs.append(log)
        todayOz += amount
        saveLogs()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func deleteLog(at offsets: IndexSet) {
        if let index = offsets.first {
            todayOz = max(0, todayOz - logs[index].amount)
            logs.remove(atOffsets: offsets)
            saveLogs()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    private func saveLogs() {
        if let encoded = try? JSONEncoder().encode(logs) {
            defaults?.set(encoded, forKey: logsKey)
            defaults?.set(Date(), forKey: lastDateKey)
        }
    }
    
    private func loadLogs() {
        let lastDate = defaults?.object(forKey: lastDateKey) as? Date ?? Date.distantPast
        if Calendar.current.isDateInToday(lastDate),
           let data = defaults?.data(forKey: logsKey),
           let decoded = try? JSONDecoder().decode([WaterLog].self, from: data) {
            logs = decoded
            todayOz = logs.reduce(0) { $0 + $1.amount }
        }
    }
    
    func purchasePro() {
        isPro = true
        defaults?.set(true, forKey: proKey)
    }
}
