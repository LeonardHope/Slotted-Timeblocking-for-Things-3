import Foundation
import GRDB

/// Manages the read-only connection to the Things 3 SQLite database.
final class Things3Database {
    let dbPool: DatabasePool

    init() throws {
        let path = try Self.findDatabasePath()
        var config = Configuration()
        config.readonly = true
        self.dbPool = try DatabasePool(path: path, configuration: config)
    }

    init(path: String) throws {
        var config = Configuration()
        config.readonly = true
        self.dbPool = try DatabasePool(path: path, configuration: config)
    }

    /// Finds the Things 3 database path by globbing for the ThingsData-* directory.
    static func findDatabasePath() throws -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let groupContainer = home.appendingPathComponent(
            "Library/Group Containers/JLMPQHK86H.com.culturedcode.ThingsMac"
        )

        let contents = try FileManager.default.contentsOfDirectory(
            at: groupContainer,
            includingPropertiesForKeys: [.contentModificationDateKey]
        )

        let thingsDataDirs = contents
            .filter { $0.lastPathComponent.hasPrefix("ThingsData-") }
            .sorted { a, b in
                let aDate = (try? a.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let bDate = (try? b.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return aDate > bDate
            }

        guard let thingsDataDir = thingsDataDirs.first else {
            throw Things3Error.databaseNotFound(
                "No ThingsData-* directory found in \(groupContainer.path)"
            )
        }

        let dbPath = thingsDataDir
            .appendingPathComponent("Things Database.thingsdatabase")
            .appendingPathComponent("main.sqlite")
            .path

        guard FileManager.default.fileExists(atPath: dbPath) else {
            throw Things3Error.databaseNotFound("Database file not found at \(dbPath)")
        }

        return dbPath
    }

    // MARK: - Queries

    /// Fetches all open, non-trashed to-do items with joined project/area/heading titles.
    func fetchOpenTasks() throws -> [Things3TaskRecord] {
        try dbPool.read { db in
            try Things3TaskRecord.fetchAll(db, sql: """
                SELECT DISTINCT
                    TASK.uuid,
                    TASK.title,
                    TASK.notes,
                    TASK.type,
                    TASK.status,
                    TASK.start,
                    TASK.startDate,
                    TASK.deadline,
                    TASK.trashed,
                    TASK.todayIndex,
                    TASK.project,
                    TASK.area,
                    TASK.heading,
                    TASK.checklistItemsCount,
                    TASK.openChecklistItemsCount,
                    TASK.creationDate,
                    TASK.userModificationDate,
                    TASK.stopDate,
                    TASK."index",
                    PROJECT.title AS projectTitle,
                    AREA.title AS areaTitle,
                    HEADING.title AS headingTitle
                FROM TMTask AS TASK
                LEFT JOIN TMTask PROJECT ON TASK.project = PROJECT.uuid
                LEFT JOIN TMArea AREA ON COALESCE(TASK.area, PROJECT.area) = AREA.uuid
                LEFT JOIN TMTask HEADING ON TASK.heading = HEADING.uuid
                LEFT JOIN TMTask HEADING_PROJECT ON HEADING.project = HEADING_PROJECT.uuid
                WHERE TASK.type = 0
                    AND TASK.status = 0
                    AND TASK.trashed = 0
                    AND (PROJECT.uuid IS NULL OR PROJECT.trashed = 0)
                    AND (HEADING.uuid IS NULL OR HEADING_PROJECT.uuid IS NULL OR HEADING_PROJECT.trashed = 0)
                ORDER BY TASK."index"
                """)
        }
    }

    /// Fetches all projects (type=1, non-trashed).
    func fetchProjects() throws -> [Things3TaskRecord] {
        try dbPool.read { db in
            try Things3TaskRecord.fetchAll(db, sql: """
                SELECT
                    TASK.uuid,
                    TASK.title,
                    TASK.notes,
                    TASK.type,
                    TASK.status,
                    TASK.start,
                    TASK.startDate,
                    TASK.deadline,
                    TASK.trashed,
                    TASK.todayIndex,
                    TASK.project,
                    TASK.area,
                    TASK.heading,
                    TASK.checklistItemsCount,
                    TASK.openChecklistItemsCount,
                    TASK.creationDate,
                    TASK.userModificationDate,
                    TASK.stopDate,
                    TASK."index",
                    NULL AS projectTitle,
                    AREA.title AS areaTitle,
                    NULL AS headingTitle
                FROM TMTask AS TASK
                LEFT JOIN TMArea AREA ON TASK.area = AREA.uuid
                WHERE TASK.type = 1
                    AND TASK.trashed = 0
                ORDER BY TASK."index"
                """)
        }
    }

    /// Fetches all tags.
    func fetchTags() throws -> [Things3TagRecord] {
        try dbPool.read { db in
            try Things3TagRecord.fetchAll(db, sql: """
                SELECT uuid, title, shortcut, parent, "index"
                FROM TMTag
                ORDER BY "index"
                """)
        }
    }

    /// Fetches all areas.
    func fetchAreas() throws -> [Things3AreaRecord] {
        try dbPool.read { db in
            try Things3AreaRecord.fetchAll(db, sql: """
                SELECT uuid, title, visible, "index"
                FROM TMArea
                ORDER BY "index"
                """)
        }
    }

    /// Fetches all task-tag associations for the given task UUIDs.
    func fetchTaskTags(for taskUUIDs: [String]) throws -> [String: [String]] {
        guard !taskUUIDs.isEmpty else { return [:] }
        return try dbPool.read { db in
            let placeholders = taskUUIDs.map { _ in "?" }.joined(separator: ",")
            let rows = try Things3TaskTagRecord.fetchAll(db, sql: """
                SELECT TT.tasks, TAG.title AS tags
                FROM TMTaskTag TT
                JOIN TMTag TAG ON TT.tags = TAG.uuid
                WHERE TT.tasks IN (\(placeholders))
                """, arguments: StatementArguments(taskUUIDs))

            var result: [String: [String]] = [:]
            for row in rows {
                result[row.tasks, default: []].append(row.tags)
            }
            return result
        }
    }
}

enum Things3Error: LocalizedError {
    case databaseNotFound(String)
    case readFailed

    var errorDescription: String? {
        switch self {
        case .databaseNotFound(let message):
            return "Things 3 database not found: \(message)"
        case .readFailed:
            return "Couldn't read the Things 3 database. Things 3 may have updated its data format — check for a Slotted update, or re-select the database in case it moved."
        }
    }
}
