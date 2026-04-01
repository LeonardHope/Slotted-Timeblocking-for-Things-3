import CloudKit

/// Converts between GRDB models and CKRecords.
enum CloudKitBridge {
    static let containerID = "iCloud.com.timebox.TimeboxForThings3"
    static let zoneName = "ScheduleZone"

    static var zoneID: CKRecordZone.ID {
        CKRecordZone.ID(zoneName: zoneName, ownerName: CKCurrentUserDefaultName)
    }

    static var container: CKContainer {
        CKContainer(identifier: containerID)
    }

    // MARK: - TimeBlock

    static func recordID(for block: TimeBlock) -> CKRecord.ID {
        CKRecord.ID(recordName: block.id, zoneID: zoneID)
    }

    static func toCKRecord(_ block: TimeBlock) -> CKRecord {
        let record = CKRecord(recordType: "TimeBlock", recordID: recordID(for: block))
        record["taskUUID"] = block.taskUUID
        record["date"] = block.date
        record["startTime"] = block.startTime as NSNumber
        record["duration"] = block.duration as NSNumber
        record["colorIndex"] = block.colorIndex.map { $0 as NSNumber }
        record["createdAt"] = block.createdAt as NSNumber
        record["updatedAt"] = block.updatedAt as NSNumber
        return record
    }

    static func timeBlock(from record: CKRecord) -> TimeBlock? {
        guard record.recordType == "TimeBlock",
              let taskUUID = record["taskUUID"] as? String,
              let date = record["date"] as? String,
              let startTime = record["startTime"] as? Int,
              let duration = record["duration"] as? Int,
              let createdAt = record["createdAt"] as? Double,
              let updatedAt = record["updatedAt"] as? Double
        else { return nil }

        return TimeBlock(
            id: record.recordID.recordName,
            taskUUID: taskUUID,
            date: date,
            startTime: startTime,
            duration: duration,
            colorIndex: record["colorIndex"] as? Int,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    static func applyToServerRecord(_ block: TimeBlock, serverRecord: CKRecord) -> CKRecord {
        serverRecord["taskUUID"] = block.taskUUID
        serverRecord["date"] = block.date
        serverRecord["startTime"] = block.startTime as NSNumber
        serverRecord["duration"] = block.duration as NSNumber
        serverRecord["colorIndex"] = block.colorIndex.map { $0 as NSNumber }
        serverRecord["createdAt"] = block.createdAt as NSNumber
        serverRecord["updatedAt"] = block.updatedAt as NSNumber
        return serverRecord
    }

    // MARK: - StandaloneBlock

    static func recordID(for block: StandaloneBlock) -> CKRecord.ID {
        CKRecord.ID(recordName: block.id, zoneID: zoneID)
    }

    static func toCKRecord(_ block: StandaloneBlock) -> CKRecord {
        let record = CKRecord(recordType: "StandaloneBlock", recordID: recordID(for: block))
        record["title"] = block.title
        record["date"] = block.date
        record["startTime"] = block.startTime as NSNumber
        record["duration"] = block.duration as NSNumber
        record["colorIndex"] = block.colorIndex as NSNumber
        record["createdAt"] = block.createdAt as NSNumber
        record["updatedAt"] = block.updatedAt as NSNumber
        return record
    }

    static func standaloneBlock(from record: CKRecord) -> StandaloneBlock? {
        guard record.recordType == "StandaloneBlock",
              let title = record["title"] as? String,
              let date = record["date"] as? String,
              let startTime = record["startTime"] as? Int,
              let duration = record["duration"] as? Int,
              let colorIndex = record["colorIndex"] as? Int,
              let createdAt = record["createdAt"] as? Double,
              let updatedAt = record["updatedAt"] as? Double
        else { return nil }

        return StandaloneBlock(
            id: record.recordID.recordName,
            title: title,
            date: date,
            startTime: startTime,
            duration: duration,
            colorIndex: colorIndex,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    static func applyToServerRecord(_ block: StandaloneBlock, serverRecord: CKRecord) -> CKRecord {
        serverRecord["title"] = block.title
        serverRecord["date"] = block.date
        serverRecord["startTime"] = block.startTime as NSNumber
        serverRecord["duration"] = block.duration as NSNumber
        serverRecord["colorIndex"] = block.colorIndex as NSNumber
        serverRecord["createdAt"] = block.createdAt as NSNumber
        serverRecord["updatedAt"] = block.updatedAt as NSNumber
        return serverRecord
    }
}
