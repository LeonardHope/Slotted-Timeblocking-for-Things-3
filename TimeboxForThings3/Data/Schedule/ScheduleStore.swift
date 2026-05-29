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

    init(demoMode: Bool = false) throws {
        let url = try Self.databaseURL(demoMode: demoMode)
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
            timeBlocks.sort { $0.startTime < $1.startTime }
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
            standaloneBlocks.sort { $0.startTime < $1.startTime }
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
        let (tbIDs, sbIDs) = try dbPool.write { db -> ([String], [String]) in
            let tbIDs = try TimeBlock.filter(Column("date") == dateString).fetchAll(db).map(\.id)
            let sbIDs = try StandaloneBlock.filter(Column("date") == dateString).fetchAll(db).map(\.id)
            _ = try TimeBlock.filter(Column("date") == dateString).deleteAll(db)
            _ = try StandaloneBlock.filter(Column("date") == dateString).deleteAll(db)
            return (tbIDs, sbIDs)
        }
        if dateString == currentDateString {
            timeBlocks.removeAll()
            standaloneBlocks.removeAll()
        }
        for id in tbIDs { notifyDeleted(id, "TimeBlock") }
        for id in sbIDs { notifyDeleted(id, "StandaloneBlock") }
    }

    /// Carry recurring standalone blocks (lunch, breaks, etc.) forward into `targetDate`.
    ///
    /// Copies the standalone blocks from the most recent prior date that has any —
    /// so routines survive even if the app wasn't running for a few days. Task-linked
    /// time blocks are intentionally *not* carried forward. No-op if the target date
    /// already has standalone blocks (so we never duplicate on repeated launches).
    func carryForwardStandaloneBlocks(to targetDate: Date) throws {
        let targetDateString = Self.isoDateString(from: targetDate)

        let (alreadyPopulated, sourceDateString) = try dbPool.read { db -> (Bool, String?) in
            let existing = try StandaloneBlock
                .filter(Column("date") == targetDateString)
                .fetchCount(db)
            let source = try String.fetchOne(
                db,
                sql: "SELECT date FROM standaloneBlock WHERE date < ? ORDER BY date DESC LIMIT 1",
                arguments: [targetDateString]
            )
            return (existing > 0, source)
        }

        guard !alreadyPopulated, let sourceDateString else { return }

        let sourceBlocks = try dbPool.read { db in
            try StandaloneBlock
                .filter(Column("date") == sourceDateString)
                .order(Column("startTime"))
                .fetchAll(db)
        }

        let now = Date().timeIntervalSince1970
        var newBlocks: [StandaloneBlock] = []
        try dbPool.write { db in
            for var block in sourceBlocks {
                block.id = UUID().uuidString
                block.date = targetDateString
                block.createdAt = now
                block.updatedAt = now
                try block.insert(db)
                newBlocks.append(block)
            }
        }

        if targetDateString == currentDateString {
            standaloneBlocks.append(contentsOf: newBlocks)
            standaloneBlocks.sort { $0.startTime < $1.startTime }
        }
        for block in newBlocks { notifySaved(block) }
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

    /// Look up a single time block by ID from the database (not just in-memory).
    func fetchTimeBlock(id: String) throws -> TimeBlock? {
        try dbPool.read { db in
            try TimeBlock.fetchOne(db, key: id)
        }
    }

    func fetchStandaloneBlock(id: String) throws -> StandaloneBlock? {
        try dbPool.read { db in
            try StandaloneBlock.fetchOne(db, key: id)
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

    private static let isoFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    static func isoDateString(from date: Date) -> String {
        isoFormatter.string(from: date)
    }

    private static func databaseURL(demoMode: Bool = false) throws -> URL {
        let appSupport = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dir = appSupport.appendingPathComponent("TimeboxForThings3", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let filename = demoMode ? "schedule-demo.sqlite" : "schedule.sqlite"
        return dir.appendingPathComponent(filename)
    }
}
