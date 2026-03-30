import Foundation
import GRDB

private func format12Hour(_ totalMinutes: Int) -> String {
    let h = totalMinutes / 60
    let m = totalMinutes % 60
    let period = h >= 12 ? "pm" : "am"
    let hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h)
    return m == 0 ? "\(hour12)\(period)" : "\(hour12):\(String(format: "%02d", m))\(period)"
}

/// A task scheduled on the time grid.
struct TimeBlock: Identifiable, Hashable, Codable, FetchableRecord, PersistableRecord {
    var id: String
    var taskUUID: String
    var date: String
    var startTime: Int
    var duration: Int
    var createdAt: Double
    var updatedAt: Double

    static let databaseTableName = "timeBlock"

    var endTime: Int { startTime + duration }

    var timeRangeDisplay: String {
        "\(format12Hour(startTime)) – \(format12Hour(endTime))"
    }
}

/// A standalone time block not linked to any task (e.g., "Lunch", "Meeting").
struct StandaloneBlock: Identifiable, Hashable, Codable, FetchableRecord, PersistableRecord {
    var id: String
    var title: String
    var date: String
    var startTime: Int
    var duration: Int
    var colorIndex: Int
    var createdAt: Double
    var updatedAt: Double

    static let databaseTableName = "standaloneBlock"

    var endTime: Int { startTime + duration }

    var timeRangeDisplay: String {
        "\(format12Hour(startTime)) – \(format12Hour(endTime))"
    }
}
