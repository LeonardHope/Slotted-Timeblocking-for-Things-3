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
    var error: Error?

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

    init() {
        self.taskProvider = Things3Provider()

        let defaults = UserDefaults.standard
        // Register defaults for first launch
        defaults.register(defaults: ["startHour": 9, "endHour": 17, "appearanceMode": 0])

        self.startHour = defaults.integer(forKey: "startHour")
        self.endHour = defaults.integer(forKey: "endHour")
        self.appearanceMode = AppearanceMode(rawValue: defaults.integer(forKey: "appearanceMode")) ?? .auto
    }

    func initialize() async {
        await taskProvider.startObserving()

        do {
            scheduleStore = try ScheduleStore()
            try await scheduleStore?.loadBlocks(for: selectedDate)
        } catch {
            self.error = error
        }
    }

    func changeDate(to date: Date) async {
        selectedDate = date
        try? await scheduleStore?.loadBlocks(for: date)
    }

    var preferredColorScheme: ColorScheme? {
        switch appearanceMode {
        case .auto: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
