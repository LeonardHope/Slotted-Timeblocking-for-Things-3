import CloudKit
import os

/// Syncs schedule data to iCloud via CKSyncEngine.
@MainActor
final class ScheduleSyncEngine {
    private let syncEngine: CKSyncEngine
    private let store: ScheduleStore
    private let delegate: SyncDelegate
    private let logger = Logger(subsystem: "com.timebox.TimeboxForThings3", category: "sync")

    init(store: ScheduleStore) throws {
        self.store = store
        self.delegate = SyncDelegate(store: store)

        let database = CloudKitBridge.container.privateCloudDatabase

        let stateSerialization = Self.loadState()

        let config = CKSyncEngine.Configuration(
            database: database,
            stateSerialization: stateSerialization,
            delegate: delegate
        )

        syncEngine = CKSyncEngine(config)
        delegate.engine = syncEngine

        store.onSyncChange = { [weak delegate] (change: SyncChange) in
            delegate?.handleLocalChange(change)
        }
    }

    func pushAllExistingRecords() {
        do {
            var pending: [CKSyncEngine.PendingRecordZoneChange] = []
            for block in try store.allTimeBlocks() {
                pending.append(.saveRecord(CloudKitBridge.recordID(for: block)))
            }
            for block in try store.allStandaloneBlocks() {
                pending.append(.saveRecord(CloudKitBridge.recordID(for: block)))
            }
            if !pending.isEmpty {
                syncEngine.state.add(pendingRecordZoneChanges: pending)
                logger.info("Queued \(pending.count) records for initial sync")
            }
        } catch {
            logger.error("Failed to queue existing records: \(error)")
        }
    }

    // MARK: - State persistence

    private static var stateURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("TimeboxForThings3", isDirectory: true)
        return dir.appendingPathComponent("sync-engine-state.json")
    }

    private static func loadState() -> CKSyncEngine.State.Serialization? {
        guard let data = try? Data(contentsOf: stateURL) else { return nil }
        return try? JSONDecoder().decode(CKSyncEngine.State.Serialization.self, from: data)
    }

    fileprivate static func saveState(_ serialization: CKSyncEngine.State.Serialization) {
        guard let data = try? JSONEncoder().encode(serialization) else { return }
        try? data.write(to: stateURL, options: .atomic)
    }
}

// MARK: - CKSyncEngineDelegate

@MainActor
private final class SyncDelegate: CKSyncEngineDelegate {
    let store: ScheduleStore
    weak var engine: CKSyncEngine?
    private let logger = Logger(subsystem: "com.timebox.TimeboxForThings3", category: "sync")

    init(store: ScheduleStore) {
        self.store = store
    }

    func handleLocalChange(_ change: SyncChange) {
        guard let engine else { return }
        switch change {
        case .saved(let recordID, _):
            engine.state.add(pendingRecordZoneChanges: [.saveRecord(recordID)])
        case .deleted(let recordID, _):
            engine.state.add(pendingRecordZoneChanges: [.deleteRecord(recordID)])
        }
    }

    // MARK: - Protocol methods

    nonisolated func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async {
        await handleEventOnMain(event)
    }

    private func handleEventOnMain(_ event: CKSyncEngine.Event) {
        switch event {
        case .stateUpdate(let event):
            ScheduleSyncEngine.saveState(event.stateSerialization)

        case .fetchedRecordZoneChanges(let event):
            applyRemoteChanges(event)

        case .sentRecordZoneChanges(let event):
            handleSentChanges(event)

        case .accountChange, .fetchedDatabaseChanges,
             .willFetchChanges, .didFetchChanges,
             .willSendChanges, .didSendChanges:
            break

        @unknown default:
            break
        }
    }

    nonisolated func nextRecordZoneChangeBatch(
        _ context: CKSyncEngine.SendChangesContext,
        syncEngine: CKSyncEngine
    ) async -> CKSyncEngine.RecordZoneChangeBatch? {
        await buildBatch(context, syncEngine: syncEngine)
    }

    private func buildBatch(
        _ context: CKSyncEngine.SendChangesContext,
        syncEngine: CKSyncEngine
    ) async -> CKSyncEngine.RecordZoneChangeBatch? {
        let pending = syncEngine.state.pendingRecordZoneChanges
            .filter { context.options.scope.contains($0) }

        guard !pending.isEmpty else { return nil }

        // Pre-build all CKRecords on the main actor
        var recordsByID: [CKRecord.ID: CKRecord] = [:]
        for change in pending {
            if case .saveRecord(let recordID) = change {
                let id = recordID.recordName
                if let b = store.timeBlocks.first(where: { $0.id == id }) {
                    recordsByID[recordID] = CloudKitBridge.toCKRecord(b)
                } else if let b = store.standaloneBlocks.first(where: { $0.id == id }) {
                    recordsByID[recordID] = CloudKitBridge.toCKRecord(b)
                } else if let b = (try? store.allTimeBlocks())?.first(where: { $0.id == id }) {
                    recordsByID[recordID] = CloudKitBridge.toCKRecord(b)
                } else if let b = (try? store.allStandaloneBlocks())?.first(where: { $0.id == id }) {
                    recordsByID[recordID] = CloudKitBridge.toCKRecord(b)
                }
            }
        }

        let records = recordsByID
        return await CKSyncEngine.RecordZoneChangeBatch(pendingChanges: Array(pending)) { recordID in
            records[recordID]
        }
    }

    // MARK: - Apply remote changes

    private func applyRemoteChanges(_ event: CKSyncEngine.Event.FetchedRecordZoneChanges) {
        for modification in event.modifications {
            let record = modification.record
            do {
                switch record.recordType {
                case "TimeBlock":
                    if let block = CloudKitBridge.timeBlock(from: record) {
                        // If local is newer, re-push local
                        if let existing = store.timeBlocks.first(where: { $0.id == block.id }),
                           existing.updatedAt > block.updatedAt {
                            engine?.state.add(pendingRecordZoneChanges: [.saveRecord(record.recordID)])
                        } else {
                            try store.upsertTimeBlock(block)
                        }
                    }
                case "StandaloneBlock":
                    if let block = CloudKitBridge.standaloneBlock(from: record) {
                        if let existing = store.standaloneBlocks.first(where: { $0.id == block.id }),
                           existing.updatedAt > block.updatedAt {
                            engine?.state.add(pendingRecordZoneChanges: [.saveRecord(record.recordID)])
                        } else {
                            try store.upsertStandaloneBlock(block)
                        }
                    }
                default:
                    break
                }
            } catch {
                logger.error("Failed to apply remote change: \(error)")
            }
        }

        for deletion in event.deletions {
            let id = deletion.recordID.recordName
            let type: String = deletion.recordType
            switch type {
            case "TimeBlock":
                try? store.deleteTimeBlockSilently(id: id)
            case "StandaloneBlock":
                try? store.deleteStandaloneBlockSilently(id: id)
            default:
                break
            }
        }
    }

    // MARK: - Handle sent changes

    private func handleSentChanges(_ event: CKSyncEngine.Event.SentRecordZoneChanges) {
        for failure in event.failedRecordSaves {
            if failure.error.code == .serverRecordChanged,
               let serverRecord = failure.error.serverRecord {
                switch serverRecord.recordType {
                case "TimeBlock":
                    if let b = CloudKitBridge.timeBlock(from: serverRecord) {
                        try? store.upsertTimeBlock(b)
                    }
                case "StandaloneBlock":
                    if let b = CloudKitBridge.standaloneBlock(from: serverRecord) {
                        try? store.upsertStandaloneBlock(b)
                    }
                default:
                    break
                }
            } else {
                logger.error("Sync save failed: \(failure.error)")
            }
        }
    }
}

// MARK: - Silent delete (no sync notification, for applying remote deletions)

extension ScheduleStore {
    func deleteTimeBlockSilently(id: String) throws {
        try dbPool.write { db in
            try TimeBlock.deleteOne(db, key: id)
        }
        timeBlocks.removeAll { $0.id == id }
    }

    func deleteStandaloneBlockSilently(id: String) throws {
        try dbPool.write { db in
            try StandaloneBlock.deleteOne(db, key: id)
        }
        standaloneBlocks.removeAll { $0.id == id }
    }
}
