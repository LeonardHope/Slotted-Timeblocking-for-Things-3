import CloudKit
import Foundation
import Observation
import os
import SwiftUI

enum AppearanceMode: Int, CaseIterable, Hashable {
    case auto = 0
    case light = 1
    case dark = 2
}

/// Top-level application state shared across the app.
@Observable
@MainActor
final class AppState {
    var taskProvider: any TaskProvider
    var scheduleStore: ScheduleStore?
    var calendarProvider = CalendarProvider()
    var databaseAccessManager = DatabaseAccessManager()
    var selectedDate: Date = .now
    var dragDropCoordinator = DragDropCoordinator()
    var selectedBlockID: String?
    var needsOnboarding = false
    var error: Error?

    private var dayChangeObserver: Any?
    private var calendarObserver: Any?

    /// Task UUIDs that are currently scheduled on the RHS
    var scheduledTaskUUIDs: Set<String> {
        guard let store = scheduleStore else { return [] }
        return Set(store.timeBlocks.map(\.taskUUID))
    }

    // Persisted preferences
    var startHour: Int {
        didSet { UserDefaults.standard.set(startHour, forKey: "startHour") }
    }
    var endHour: Int {
        didSet { UserDefaults.standard.set(endHour, forKey: "endHour") }
    }
    var appearanceMode: AppearanceMode {
        didSet { UserDefaults.standard.set(appearanceMode.rawValue, forKey: "appearanceMode") }
    }
    var textScale: Double {
        didSet { UserDefaults.standard.set(textScale, forKey: "textScale") }
    }
    var hideEmptyCategories: Bool {
        didSet { UserDefaults.standard.set(hideEmptyCategories, forKey: "hideEmptyCategories") }
    }
    var hideEmptyProjects: Bool {
        didSet { UserDefaults.standard.set(hideEmptyProjects, forKey: "hideEmptyProjects") }
    }
    var showCurrentTimeLine: Bool {
        didSet { UserDefaults.standard.set(showCurrentTimeLine, forKey: "showCurrentTimeLine") }
    }
    var showDates: Bool {
        didSet { UserDefaults.standard.set(showDates, forKey: "showDates") }
    }
    var clearAtMidnight: Bool {
        didSet { UserDefaults.standard.set(clearAtMidnight, forKey: "clearAtMidnight") }
    }
    var hideScheduledTasks: Bool {
        didSet { UserDefaults.standard.set(hideScheduledTasks, forKey: "hideScheduledTasks") }
    }
    var showCalendarEvents: Bool {
        didSet {
            UserDefaults.standard.set(showCalendarEvents, forKey: "showCalendarEvents")
            if showCalendarEvents {
                Task { await enableCalendar() }
            } else {
                calendarProvider.events = []
            }
        }
    }
    var iCloudSyncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(iCloudSyncEnabled, forKey: "iCloudSyncEnabled")
            if iCloudSyncEnabled {
                Task { await startSyncEngine() }
            } else {
                syncEngine = nil
            }
        }
    }

    private(set) var syncEngine: ScheduleSyncEngine?

    init() {
        if MockTaskProvider.isEnabled {
            self.taskProvider = MockTaskProvider()
        } else {
            self.taskProvider = Things3Provider()
        }

        let defaults = UserDefaults.standard
        defaults.register(defaults: ["startHour": 9, "endHour": 17, "appearanceMode": 0, "textScale": 1.0, "hideEmptyCategories": true, "hideEmptyProjects": true, "showCurrentTimeLine": true, "showDates": true, "clearAtMidnight": true, "hideScheduledTasks": true, "iCloudSyncEnabled": false, "showCalendarEvents": false])

        self.startHour = defaults.integer(forKey: "startHour")
        self.endHour = defaults.integer(forKey: "endHour")
        self.appearanceMode = AppearanceMode(rawValue: defaults.integer(forKey: "appearanceMode")) ?? .auto
        self.textScale = defaults.double(forKey: "textScale")
        self.hideEmptyCategories = defaults.bool(forKey: "hideEmptyCategories")
        self.hideEmptyProjects = defaults.bool(forKey: "hideEmptyProjects")
        self.showCurrentTimeLine = defaults.bool(forKey: "showCurrentTimeLine")
        self.showDates = defaults.bool(forKey: "showDates")
        self.clearAtMidnight = defaults.bool(forKey: "clearAtMidnight")
        self.hideScheduledTasks = defaults.bool(forKey: "hideScheduledTasks")
        self.showCalendarEvents = defaults.bool(forKey: "showCalendarEvents")
        self.iCloudSyncEnabled = defaults.bool(forKey: "iCloudSyncEnabled")
        if self.textScale == 0 { self.textScale = 1.0 }
        // Enforce a valid schedule window (end strictly after start).
        if self.endHour <= self.startHour {
            self.startHour = min(self.startHour, 22)
            self.endHour = self.startHour + 1
        }
    }

    func initialize() async {
        // Demo mode: skip Things 3 database access entirely
        if let things3 = taskProvider as? Things3Provider {
            if let path = databaseAccessManager.resolveAccess() {
                things3.setDatabasePath(path)
                await taskProvider.startObserving()
            } else {
                needsOnboarding = true
                return
            }
        } else {
            // Mock provider — no database needed
            await taskProvider.startObserving()
        }

        await setUpSchedule()
    }

    /// Create the schedule store, roll the schedule over to today, and start observers.
    private func setUpSchedule() async {
        do {
            let store = try ScheduleStore(demoMode: MockTaskProvider.isEnabled)
            scheduleStore = store
            // Start sync before rollover so clear/carry-forward changes propagate to iCloud
            if iCloudSyncEnabled { await startSyncEngine() }
            rolloverIfNeeded()
            try await store.loadBlocks(for: selectedDate)
            if MockTaskProvider.isEnabled {
                seedDemoSchedule()
            }
        } catch {
            self.error = error
        }

        if showCalendarEvents {
            await enableCalendar()
        }

        observeDayChange()
        observeTaskCompletions()
    }

    /// Roll the schedule over to today: clear past days or carry routines forward,
    /// per settings. Runs at launch and on the NSCalendarDayChanged notification,
    /// so a Mac that was asleep or off at midnight still rolls over correctly.
    private func rolloverIfNeeded() {
        guard let store = scheduleStore else { return }
        if clearAtMidnight {
            // Idempotent — deletes everything dated before today — so no marker needed.
            do {
                try store.clearBlocks(before: .now)
            } catch {
                self.error = error
            }
        } else {
            carryForwardRoutinesIfNeeded(to: .now)
        }
    }

    /// Listens for NSCalendarDayChanged notification from the system.
    private func observeDayChange() {
        if let old = dayChangeObserver { NotificationCenter.default.removeObserver(old) }
        dayChangeObserver = NotificationCenter.default.addObserver(
            forName: .NSCalendarDayChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.rolloverIfNeeded()
                if Calendar.current.isDateInYesterday(self.selectedDate) {
                    // The user was viewing the day that just ended — follow them to the new day
                    await self.changeDate(to: .now)
                } else {
                    // Reload in place; rollover may have changed the visible date's blocks
                    await self.changeDate(to: self.selectedDate)
                }
            }
        }
    }

    /// Called from the onboarding view when the user grants file access.
    func grantDatabaseAccess() async {
        guard let things3 = taskProvider as? Things3Provider else { return }
        switch databaseAccessManager.requestUserAccess() {
        case .granted(let path):
            things3.setDatabasePath(path)
            await taskProvider.startObserving()
            needsOnboarding = false
            await setUpSchedule()
        case .invalidSelection:
            self.error = OnboardingError.invalidSelection
        case .cancelled:
            break
        }
    }

    func changeDate(to date: Date) async {
        selectedDate = date
        try? await scheduleStore?.loadBlocks(for: date)
        if showCalendarEvents {
            calendarProvider.fetchEvents(for: date)
        }
    }

    /// Seed today's schedule with demo standalone blocks (only if empty).
    private func seedDemoSchedule() {
        guard let store = scheduleStore else { return }
        guard store.standaloneBlocks.isEmpty && store.timeBlocks.isEmpty else { return }

        let date = selectedDate
        let demos: [(title: String, start: Int, duration: Int, color: Int)] = [
            ("Morning run",        7 * 60,         45, 2),  // 7:00am – 7:45am
            ("Check emails",       9 * 60,         30, 0),  // 9:00am – 9:30am
            ("Lunch",              12 * 60,        60, 5),  // 12pm – 1pm
            ("Pick up the kids",   15 * 60,        45, 7),  // 3pm – 3:45pm
        ]

        for demo in demos {
            _ = try? store.addStandaloneBlock(
                title: demo.title,
                date: date,
                startTime: demo.start,
                duration: demo.duration,
                colorIndex: demo.color
            )
        }
    }

    private func enableCalendar() async {
        await calendarProvider.requestAccess()
        if calendarProvider.accessGranted {
            calendarProvider.fetchEvents(for: selectedDate)
            if let old = calendarObserver { NotificationCenter.default.removeObserver(old) }
            calendarObserver = NotificationCenter.default.addObserver(
                forName: .EKEventStoreChanged,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self, self.showCalendarEvents else { return }
                    self.calendarProvider.fetchEvents(for: self.selectedDate)
                }
            }
        }
    }

    private func startSyncEngine() async {
        guard let store = scheduleStore else { return }
        do {
            let status = try await CloudKitBridge.container.accountStatus()
            guard status == .available else {
                self.error = SyncError.iCloudUnavailable
                self.iCloudSyncEnabled = false
                return
            }
            let engine = try ScheduleSyncEngine(store: store)
            // Ensure the shared record zone exists without ever deleting it —
            // a second device must never wipe records pushed by the first.
            await engine.ensureZoneExists()
            // Push this device's local records once. Records that already exist
            // on the server (by record name) are reconciled by CKSyncEngine, so
            // this merges rather than overwrites across devices.
            if !UserDefaults.standard.bool(forKey: "hasPushedInitialRecords") {
                engine.pushAllExistingRecords()
                UserDefaults.standard.set(true, forKey: "hasPushedInitialRecords")
            }
            syncEngine = engine
        } catch {
            self.error = error
        }
    }

    /// Remove scheduled blocks whose tasks are no longer active in Things 3.
    private func observeTaskCompletions() {
        withObservationTracking {
            _ = taskProvider.tasks
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                self?.removeCompletedBlocks()
                self?.observeTaskCompletions()
            }
        }
    }

    private static let lastCarryForwardKey = "lastCarryForwardDate"

    /// Carry routines forward at most once per calendar day. Without this guard,
    /// the launch-time call would re-copy the previous day's routines every time
    /// the app starts — so intentionally deleting today's standalone blocks and
    /// relaunching would resurrect them. The persisted marker (an ISO date string,
    /// which sorts chronologically) ensures we only carry forward when crossing
    /// into a date we haven't carried into yet.
    private func carryForwardRoutinesIfNeeded(to date: Date) {
        let target = ScheduleStore.isoDateString(from: date)
        let last = UserDefaults.standard.string(forKey: Self.lastCarryForwardKey)
        if let last, last >= target { return }
        try? scheduleStore?.carryForwardStandaloneBlocks(to: date)
        UserDefaults.standard.set(target, forKey: Self.lastCarryForwardKey)
    }

    private func removeCompletedBlocks() {
        guard let store = scheduleStore else { return }
        // Guard against wiping the schedule while Things 3 data is still loading
        // (an empty task set would otherwise orphan every block).
        guard !taskProvider.tasks.isEmpty else { return }
        let activeTaskIDs = Set(taskProvider.tasks.map(\.id))
        // Check every date, not just the loaded one, so orphaned blocks don't
        // linger in the database (and can't be carried forward later).
        let allBlocks = (try? store.allTimeBlocks()) ?? []
        let orphanedBlocks = allBlocks.filter { !activeTaskIDs.contains($0.taskUUID) }
        for block in orphanedBlocks {
            try? store.deleteTimeBlock(id: block.id)
        }
    }

    /// Log and surface errors from store operations.
    func perform(_ operation: () throws -> Void) {
        do {
            try operation()
        } catch {
            self.error = error
            Logger(subsystem: "com.timebox.TimeboxForThings3", category: "store")
                .error("Store operation failed: \(error)")
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch appearanceMode {
        case .auto: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum OnboardingError: LocalizedError {
    case invalidSelection

    var errorDescription: String? {
        switch self {
        case .invalidSelection:
            return "That folder doesn't contain a Things 3 database. Select the \"Things Database.thingsdatabase\" folder and try again."
        }
    }
}

enum SyncError: LocalizedError {
    case iCloudUnavailable

    var errorDescription: String? {
        switch self {
        case .iCloudUnavailable:
            return "iCloud Sync is unavailable. Make sure you're signed in to iCloud in System Settings, then turn sync back on."
        }
    }
}
