import Foundation
import GRDB

/// Manages the app's own SQLite database for schedule persistence.
@Observable
@MainActor
final class ScheduleStore {
    private let dbPool: DatabasePool

    private(set) var timeBlocks: [TimeBlock] = []
    private(set) var standaloneBlocks: [StandaloneBlock] = []

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
        var block = TimeBlock(
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
    }

    func deleteTimeBlock(id: String) throws {
        try dbPool.write { db in
            try TimeBlock.deleteOne(db, key: id)
        }
        timeBlocks.removeAll { $0.id == id }
    }

    func deleteTimeBlocks(forTaskUUID uuid: String) throws {
        try dbPool.write { db in
            try TimeBlock.filter(Column("taskUUID") == uuid).deleteAll(db)
        }
        timeBlocks.removeAll { $0.taskUUID == uuid }
    }

    // MARK: - Standalone Blocks

    @discardableResult
    func addStandaloneBlock(title: String = "Untitled", date: Date, startTime: Int, duration: Int = 30, colorIndex: Int = 0) throws -> StandaloneBlock {
        let now = Date().timeIntervalSince1970
        var block = StandaloneBlock(
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
    }

    func deleteStandaloneBlock(id: String) throws {
        try dbPool.write { db in
            try StandaloneBlock.deleteOne(db, key: id)
        }
        standaloneBlocks.removeAll { $0.id == id }
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
