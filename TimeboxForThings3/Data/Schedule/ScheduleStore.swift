import Foundation
import CloudKit
import GRDB

/// Notification sent when local records change and need syncing.
enum SyncChange: Sendable {
    case saved(CKRecord.ID, String)    // recordID, recordType
    case deleted(CKRecord.ID, String)  // recordID, recordType
}

/// Manages the app's own SQLite database for schedule persistence.
@Observable
@MainActor
final class ScheduleStore {
    let dbPool: DatabasePool

    var timeBlocks: [TimeBlock] = []
    var standaloneBlocks: [StandaloneBlock] = []

    /// Called when a local write happens, so the sync engine can push changes.
    var onSyncChange: ((SyncChange) -> Void)?

    init() throws {
        let url = try Self.databaseURL()
        dbPool = try DatabasePool(path: url.path)
        try ScheduleMigrations.migrator.migrate(dbPool)
    }

    /// In-memory database for testing.
    init(inMemory: Bool) throws {
        dbPool = try DatabasePool(path: ":memory:")
        try ScheduleMigrations.migrator.migrate(dbPool)
    }

    // MARK: - Loading

    func loadBlocks(for date: Date) async throws {
        let dateString = Self.isoDateString(from: date)
        currentDateString = dateString
        let (time, standalone) = try await dbPool.read { db in
            let timeBlocks = try TimeBlock
                .filter(Column("date") == dateString)
                .order(Column("startTime"))
                .fetchAll(db)
            let standaloneBlocks = try StandaloneBlock
                .filter(Column("date") == dateString)
                .order(Column("startTime"))
                .fetchAll(db)
            return (timeBlocks, standaloneBlocks)
        }
        self.timeBlocks = time
        self.standaloneBlocks = standalone
    }

    // MARK: - Time Blocks

    @discardableResult
    func addTimeBlock(taskUUID: String, date: Date, startTime: Int, duration: Int = 30) throws -> TimeBlock {
        let now = Date().timeIntervalSince1970
        let block = TimeBlock(
            id: UUID().uuidString,
            taskUUID: taskUUID,
            date: Self.isoDateString(from: date),
            startTime: startTime,
            duration: duration,
            createdAt: now,
            updatedAt: now
        )
        try dbPool.write { db in
            try block.insert(db)
        }
        timeBlocks.append(block)
        timeBlocks.sort { $0.startTime < $1.startTime }
        notifySaved(block)
        return block
    }

    func updateTimeBlock(_ block: TimeBlock) throws {
        var updated = block
        updated.updatedAt = Date().timeIntervalSince1970
        try dbPool.write { db in
            try updated.update(db)
        }
        if let index = timeBlocks.firstIndex(where: { $0.id == block.id }) {
            timeBlocks[index] = updated
        }
        notifySaved(updated)
    }

    func deleteTimeBlock(id: String) throws {
        _ = try dbPool.write { db in
            try TimeBlock.deleteOne(db, key: id)
        }
        timeBlocks.removeAll { $0.id == id }
        notifyDeleted(id, "TimeBlock")
    }

    func deleteTimeBlocks(forTaskUUID uuid: String) throws {
        let ids = timeBlocks.filter { $0.taskUUID == uuid }.map(\.id)
        _ = try dbPool.write { db in
            try TimeBlock.filter(Column("taskUUID") == uuid).deleteAll(db)
        }
        timeBlocks.removeAll { $0.taskUUID == uuid }
        for id in ids { notifyDeleted(id, "TimeBlock") }
    }

    // MARK: - Standalone Blocks

    @discardableResult
    func addStandaloneBlock(title: String = "Untitled", date: Date, startTime: Int, duration: Int = 30, colorIndex: Int = 0) throws -> StandaloneBlock {
        let now = Date().timeIntervalSince1970
        let block = StandaloneBlock(
            id: UUID().uuidString,
            title: title,
            date: Self.isoDateString(from: date),
            startTime: startTime,
            duration: duration,
            colorIndex: colorIndex,
            createdAt: now,
            updatedAt: now
        )
        try dbPool.write { db in
            try block.insert(db)
        }
        standaloneBlocks.append(block)
        standaloneBlocks.sort { $0.startTime < $1.startTime }
        notifySaved(block)
        return block
    }

    func updateStandaloneBlock(_ block: StandaloneBlock) throws {
        var updated = block
        updated.updatedAt = Date().timeIntervalSince1970
        try dbPool.write { db in
            try updated.update(db)
        }
        if let index = standaloneBlocks.firstIndex(where: { $0.id == block.id }) {
            standaloneBlocks[index] = updated
        }
        notifySaved(updated)
    }

    func deleteStandaloneBlock(id: String) throws {
        _ = try dbPool.write { db in
            try StandaloneBlock.deleteOne(db, key: id)
        }
        standaloneBlocks.removeAll { $0.id == id }
        notifyDeleted(id, "StandaloneBlock")
    }

    // MARK: - Clear

    /// Remove all blocks for a given date.
    func clearBlocks(for date: Date) throws {
        let dateString = Self.isoDateString(from: date)
        let tbIDs = timeBlocks.map(\.id)
        let sbIDs = standaloneBlocks.map(\.id)
        try dbPool.write { db in
            try TimeBlock.filter(Column("date") == dateString).deleteAll(db)
            try StandaloneBlock.filter(Column("date") == dateString).deleteAll(db)
        }
        timeBlocks.removeAll()
        standaloneBlocks.removeAll()
        for id in tbIDs { notifyDeleted(id, "TimeBlock") }
        for id in sbIDs { notifyDeleted(id, "StandaloneBlock") }
    }

    /// Copy all blocks from one date to another (for carrying blocks into the next day).
    func copyBlocks(from sourceDate: Date, to targetDate: Date) throws {
        let sourceDateString = Self.isoDateString(from: sourceDate)
        let targetDateString = Self.isoDateString(from: targetDate)
        let now = Date().timeIntervalSince1970

        let sourceTimeBlocks = try dbPool.read { db in
            try TimeBlock.filter(Column("date") == sourceDateString).fetchAll(db)
        }
        let sourceStandaloneBlocks = try dbPool.read { db in
            try StandaloneBlock.filter(Column("date") == sourceDateString).fetchAll(db)
        }

        for var block in sourceTimeBlocks {
            block.id = UUID().uuidString
            block.date = targetDateString
            block.createdAt = now
            block.updatedAt = now
            try dbPool.write { db in try block.insert(db) }
            notifySaved(block)
        }

        for var block in sourceStandaloneBlocks {
            block.id = UUID().uuidString
            block.date = targetDateString
            block.createdAt = now
            block.updatedAt = now
            try dbPool.write { db in try block.insert(db) }
            notifySaved(block)
        }
    }

    // MARK: - Upsert (for sync engine applying remote changes)

    func upsertTimeBlock(_ block: TimeBlock) throws {
        try dbPool.write { db in
            try block.save(db)
        }
        // Only update in-memory if this block is for the currently loaded date
        if let index = timeBlocks.firstIndex(where: { $0.id == block.id }) {
            timeBlocks[index] = block
        } else if block.date == currentDateString {
            timeBlocks.append(block)
            timeBlocks.sort { $0.startTime < $1.startTime }
        }
    }

    func upsertStandaloneBlock(_ block: StandaloneBlock) throws {
        try dbPool.write { db in
            try block.save(db)
        }
        if let index = standaloneBlocks.firstIndex(where: { $0.id == block.id }) {
            standaloneBlocks[index] = block
        } else if block.date == currentDateString {
            standaloneBlocks.append(block)
            standaloneBlocks.sort { $0.startTime < $1.startTime }
        }
    }

    /// The currently loaded date string, used to filter upserts.
    private(set) var currentDateString: String = ""

    /// Fetch all records across all dates (for initial sync push).
    func allTimeBlocks() throws -> [TimeBlock] {
        try dbPool.read { db in
            try TimeBlock.fetchAll(db)
        }
    }

    func allStandaloneBlocks() throws -> [StandaloneBlock] {
        try dbPool.read { db in
            try StandaloneBlock.fetchAll(db)
        }
    }

    // MARK: - Sync notifications

    private func notifySaved(_ block: TimeBlock) {
        onSyncChange?(.saved(CloudKitBridge.recordID(for: block), "TimeBlock"))
    }

    private func notifySaved(_ block: StandaloneBlock) {
        onSyncChange?(.saved(CloudKitBridge.recordID(for: block), "StandaloneBlock"))
    }

    private func notifyDeleted(_ id: String, _ type: String) {
        let recordID = CKRecord.ID(recordName: id, zoneID: CloudKitBridge.zoneID)
        onSyncChange?(.deleted(recordID, type))
    }

    // MARK: - Helpers

    static func isoDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

    private static func databaseURL() throws -> URL {
        let appSupport = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dir = appSupport.appendingPathComponent("TimeboxForThings3", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("schedule.sqlite")
    }
}
