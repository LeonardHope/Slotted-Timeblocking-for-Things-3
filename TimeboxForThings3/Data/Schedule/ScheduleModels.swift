import Foundation
import GRDB

/// A task scheduled on the time grid.
struct TimeBlock: Identifiable, Hashable, Codable, FetchableRecord, PersistableRecord {
    var id: String
    var taskUUID: String
    var date: String        // ISO date: "2026-03-30"
    var startTime: Int      // Minutes from midnight (e.g., 540 = 9:00 AM)
    var duration: Int       // Duration in minutes
    var createdAt: Double
    var updatedAt: Double

    static let databaseTableName = "timeBlock"

    /// Start time as hours and minutes.
    var startComponents: (hour: Int, minute: Int) {
        (startTime / 60, startTime % 60)
    }

    /// End time in minutes from midnight.
    var endTime: Int { startTime + duration }

    var endComponents: (hour: Int, minute: Int) {
        (endTime / 60, endTime % 60)
    }

    /// Display string like "9:00 – 9:30"
    var timeRangeDisplay: String {
        let (sh, sm) = startComponents
        let (eh, em) = endComponents
        return String(format: "%d:%02d – %d:%02d", sh, sm, eh, em)
    }
}

/// A standalone time block not linked to any task (e.g., "Lunch", "Meeting").
struct StandaloneBlock: Identifiable, Hashable, Codable, FetchableRecord, PersistableRecord {
    var id: String
    var title: String
    var date: String        // ISO date
    var startTime: Int      // Minutes from midnight
    var duration: Int       // Duration in minutes
    var colorIndex: Int     // Index into a color palette
    var createdAt: Double
    var updatedAt: Double

    static let databaseTableName = "standaloneBlock"

    var startComponents: (hour: Int, minute: Int) {
        (startTime / 60, startTime % 60)
    }

    var endTime: Int { startTime + duration }

    var endComponents: (hour: Int, minute: Int) {
        (endTime / 60, endTime % 60)
    }

    var timeRangeDisplay: String {
        let (sh, sm) = startComponents
        let (eh, em) = endComponents
        return String(format: "%d:%02d – %d:%02d", sh, sm, eh, em)
    }
}
