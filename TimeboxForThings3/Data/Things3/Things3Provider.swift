import Foundation
import Observation

/// TaskProvider implementation that reads from the Things 3 SQLite database.
/// Uses file system monitoring on the WAL file to detect changes instantly
/// instead of polling, with a fallback poll every 30s as a safety net.
@Observable
@MainActor
final class Things3Provider: TaskProvider {
    private(set) var tasks: [TaskItem] = []
    private(set) var projects: [ProjectInfo] = []
    private(set) var tags: [TagInfo] = []
    private(set) var isLoading = false
    private(set) var error: Error?

    private var database: Things3Database?
    private var fileMonitor: Things3FileMonitor?
    private var fallbackTimer: Timer?

    func startObserving() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let db = try Things3Database()
            self.database = db
            await refresh()
            startFileMonitor(dbPath: db.dbPool.path)
            startFallbackTimer()
        } catch {
            self.error = error
        }
    }

    func stopObserving() {
        fileMonitor?.stop()
        fileMonitor = nil
        fallbackTimer?.invalidate()
        fallbackTimer = nil
    }

    func refresh() async {
        guard let database else { return }

        do {
            let taskRecords = try database.fetchOpenTasks()
            let projectRecords = try database.fetchProjects()
            let tagRecords = try database.fetchTags()

            let taskUUIDs = taskRecords.map(\.uuid)
            let taskTagMap = try database.fetchTaskTags(for: taskUUIDs)

            self.tasks = taskRecords.map { record in
                record.toTaskItem(tags: taskTagMap[record.uuid] ?? [])
            }

            self.projects = projectRecords.compactMap { record in
                guard let title = record.title else { return nil }
                return ProjectInfo(
                    id: record.uuid,
                    title: title,
                    areaName: record.areaTitle
                )
            }

            self.tags = tagRecords.compactMap { record in
                guard let title = record.title else { return nil }
                return TagInfo(
                    id: record.uuid,
                    title: title,
                    shortcut: record.shortcut
                )
            }

            self.error = nil
        } catch {
            self.error = error
        }
    }

    // MARK: - File system monitoring

    /// Watches the SQLite WAL file for changes. When Things 3 writes to its
    /// database, the WAL file is modified. DispatchSource (kqueue) gives us
    /// near-instant notification with zero CPU cost when idle.
    private func startFileMonitor(dbPath: String) {
        let walPath = dbPath + "-wal"
        fileMonitor = Things3FileMonitor(path: walPath) { [weak self] in
            Task { @MainActor [weak self] in
                await self?.refresh()
            }
        }
        fileMonitor?.start()
    }

    /// Safety net: poll every 30s in case the WAL file monitor misses an event
    /// (e.g., WAL checkpoint replaces the file handle).
    private func startFallbackTimer() {
        fallbackTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refresh()
            }
        }
    }
}

// MARK: - File Monitor

/// Monitors a file for write events using GCD dispatch sources (kqueue).
final class Things3FileMonitor: @unchecked Sendable {
    private let path: String
    private let onChange: @Sendable () -> Void
    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private let queue = DispatchQueue(label: "com.timebox.filemonitor", qos: .utility)

    /// Debounce: Things 3 may write multiple WAL entries in quick succession.
    /// Wait 0.5s after the last write before refreshing.
    private var debounceWorkItem: DispatchWorkItem?
    private let debounceInterval: TimeInterval = 0.5

    init(path: String, onChange: @escaping @Sendable () -> Void) {
        self.path = path
        self.onChange = onChange
    }

    func start() {
        fileDescriptor = open(path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .extend, .rename, .delete],
            queue: queue
        )

        source.setEventHandler { [weak self] in
            self?.handleEvent()
        }

        source.setCancelHandler { [weak self] in
            guard let self, self.fileDescriptor >= 0 else { return }
            close(self.fileDescriptor)
            self.fileDescriptor = -1
        }

        self.source = source
        source.resume()
    }

    func stop() {
        debounceWorkItem?.cancel()
        source?.cancel()
        source = nil
    }

    private func handleEvent() {
        debounceWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.onChange()
        }
        debounceWorkItem = work
        queue.asyncAfter(deadline: .now() + debounceInterval, execute: work)

        // If the WAL file was deleted/renamed (e.g., checkpoint), re-watch it
        if let source, source.data.contains(.delete) || source.data.contains(.rename) {
            stop()
            // Brief delay then try to re-establish the watch
            queue.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.start()
            }
        }
    }

    deinit {
        stop()
    }
}

// MARK: - Record to Domain Model Conversion

extension Things3TaskRecord {
    func toTaskItem(tags: [String]) -> TaskItem {
        TaskItem(
            id: uuid,
            title: title ?? "",
            notes: notes,
            projectName: projectTitle,
            projectUUID: project,
            areaName: areaTitle,
            headingName: headingTitle,
            tags: tags,
            startDate: startDate.flatMap { Things3DateDecoder.decode($0) },
            deadline: deadline.flatMap { Things3DateDecoder.decode($0) },
            creationDate: creationDate.map { Date(timeIntervalSince1970: $0) },
            todayIndex: todayIndex,
            startValue: start,
            checklistTotal: checklistItemsCount,
            checklistOpen: openChecklistItemsCount
        )
    }
}
