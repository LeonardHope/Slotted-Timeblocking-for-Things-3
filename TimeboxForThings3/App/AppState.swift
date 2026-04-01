import Foundation
import Observation
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
    var taskProvider: Things3Provider
    var scheduleStore: ScheduleStore?
    var calendarProvider = CalendarProvider()
    var selectedDate: Date = .now
    var dragDropCoordinator = DragDropCoordinator()
    var selectedBlockID: String?
    var error: Error?

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
        self.taskProvider = Things3Provider()

        let defaults = UserDefaults.standard
        defaults.register(defaults: ["startHour": 9, "endHour": 17, "appearanceMode": 0, "textScale": 1.0, "hideEmptyCategories": true, "showDates": true, "clearAtMidnight": true, "hideScheduledTasks": true, "iCloudSyncEnabled": false, "showCalendarEvents": false])

        self.startHour = defaults.integer(forKey: "startHour")
        self.endHour = defaults.integer(forKey: "endHour")
        self.appearanceMode = AppearanceMode(rawValue: defaults.integer(forKey: "appearanceMode")) ?? .auto
        self.textScale = defaults.double(forKey: "textScale")
        self.hideEmptyCategories = defaults.bool(forKey: "hideEmptyCategories")
        self.showDates = defaults.bool(forKey: "showDates")
        self.clearAtMidnight = defaults.bool(forKey: "clearAtMidnight")
        self.hideScheduledTasks = defaults.bool(forKey: "hideScheduledTasks")
        self.showCalendarEvents = defaults.bool(forKey: "showCalendarEvents")
        self.iCloudSyncEnabled = defaults.bool(forKey: "iCloudSyncEnabled")
        if self.textScale == 0 { self.textScale = 1.0 }
    }

    func initialize() async {
        await taskProvider.startObserving()

        do {
            scheduleStore = try ScheduleStore()
            try await scheduleStore?.loadBlocks(for: selectedDate)
        } catch {
            self.error = error
        }

        if showCalendarEvents {
            await enableCalendar()
        }

        if iCloudSyncEnabled {
            await startSyncEngine()
        }

        observeDayChange()
        observeTaskCompletions()
    }

    /// Listens for NSCalendarDayChanged notification from the system.
    private func observeDayChange() {
        NotificationCenter.default.addObserver(
            forName: .NSCalendarDayChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let today = Date.now
                let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
                if self.clearAtMidnight {
                    try? self.scheduleStore?.clearBlocks(for: yesterday)
                } else {
                    // Copy yesterday's blocks to today so recurring blocks carry forward
                    try? self.scheduleStore?.copyBlocks(from: yesterday, to: today)
                }
                await self.changeDate(to: today)
            }
        }
    }

    func changeDate(to date: Date) async {
        selectedDate = date
        try? await scheduleStore?.loadBlocks(for: date)
        if showCalendarEvents {
            calendarProvider.fetchEvents(for: date)
        }
    }

    private func enableCalendar() async {
        await calendarProvider.requestAccess()
        if calendarProvider.accessGranted {
            calendarProvider.fetchEvents(for: selectedDate)
            // Re-fetch when calendar changes
            NotificationCenter.default.addObserver(
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
            // On first sync, clear stale state and zone before creating engine
            if !UserDefaults.standard.bool(forKey: "hasPerformedInitialSyncV2") {
                await ScheduleSyncEngine.resetZoneAndState()
                let engine = try ScheduleSyncEngine(store: store)
                engine.pushAllExistingRecords()
                UserDefaults.standard.set(true, forKey: "hasPerformedInitialSyncV2")
                syncEngine = engine
            } else {
                let engine = try ScheduleSyncEngine(store: store)
                syncEngine = engine
            }
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

    private func removeCompletedBlocks() {
        guard let store = scheduleStore else { return }
        let activeTaskIDs = Set(taskProvider.tasks.map(\.id))
        let orphanedBlocks = store.timeBlocks.filter { !activeTaskIDs.contains($0.taskUUID) }
        for block in orphanedBlocks {
            try? store.deleteTimeBlock(id: block.id)
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
