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
    var iCloudSyncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(iCloudSyncEnabled, forKey: "iCloudSyncEnabled")
            if iCloudSyncEnabled {
                startSyncEngine()
            } else {
                syncEngine = nil
            }
        }
    }

    private(set) var syncEngine: ScheduleSyncEngine?

    init() {
        self.taskProvider = Things3Provider()

        let defaults = UserDefaults.standard
        defaults.register(defaults: ["startHour": 9, "endHour": 17, "appearanceMode": 0, "textScale": 1.0, "hideEmptyCategories": true, "showDates": true, "clearAtMidnight": true, "iCloudSyncEnabled": false])

        self.startHour = defaults.integer(forKey: "startHour")
        self.endHour = defaults.integer(forKey: "endHour")
        self.appearanceMode = AppearanceMode(rawValue: defaults.integer(forKey: "appearanceMode")) ?? .auto
        self.textScale = defaults.double(forKey: "textScale")
        self.hideEmptyCategories = defaults.bool(forKey: "hideEmptyCategories")
        self.showDates = defaults.bool(forKey: "showDates")
        self.clearAtMidnight = defaults.bool(forKey: "clearAtMidnight")
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

        if iCloudSyncEnabled {
            startSyncEngine()
        }

        observeDayChange()
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
                if self.clearAtMidnight {
                    try? self.scheduleStore?.clearBlocks(for: self.selectedDate)
                }
                await self.changeDate(to: .now)
            }
        }
    }

    func changeDate(to date: Date) async {
        selectedDate = date
        try? await scheduleStore?.loadBlocks(for: date)
    }

    private func startSyncEngine() {
        guard let store = scheduleStore else { return }
        do {
            let engine = try ScheduleSyncEngine(store: store)
            // On first launch with sync, push all existing records
            if !UserDefaults.standard.bool(forKey: "hasPerformedInitialSync") {
                engine.pushAllExistingRecords()
                UserDefaults.standard.set(true, forKey: "hasPerformedInitialSync")
            }
            syncEngine = engine
        } catch {
            self.error = error
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
