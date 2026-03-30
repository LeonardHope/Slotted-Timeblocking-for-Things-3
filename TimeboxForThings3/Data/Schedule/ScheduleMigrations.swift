import Foundation
import GRDB

/// Database migrations for the schedule storage.
enum ScheduleMigrations {
    static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_create_tables") { db in
            try db.create(table: "timeBlock") { t in
                t.primaryKey("id", .text)
                t.column("taskUUID", .text).notNull()
                t.column("date", .text).notNull()
                t.column("startTime", .integer).notNull()
                t.column("duration", .integer).notNull().defaults(to: 30)
                t.column("createdAt", .double).notNull()
                t.column("updatedAt", .double).notNull()
            }

            try db.create(index: "idx_timeBlock_date", on: "timeBlock", columns: ["date"])
            try db.create(index: "idx_timeBlock_taskUUID", on: "timeBlock", columns: ["taskUUID"])

            try db.create(table: "standaloneBlock") { t in
                t.primaryKey("id", .text)
                t.column("title", .text).notNull().defaults(to: "Untitled")
                t.column("date", .text).notNull()
                t.column("startTime", .integer).notNull()
                t.column("duration", .integer).notNull().defaults(to: 30)
                t.column("colorIndex", .integer).notNull().defaults(to: 0)
                t.column("createdAt", .double).notNull()
                t.column("updatedAt", .double).notNull()
            }

            try db.create(index: "idx_standaloneBlock_date", on: "standaloneBlock", columns: ["date"])
        }

        return migrator
    }
}
