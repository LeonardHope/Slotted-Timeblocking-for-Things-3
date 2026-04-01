import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.needsOnboarding {
                OnboardingView(
                    onGrantAccess: {
                        Task { await appState.grantDatabaseAccess() }
                    }
                )
            } else {
                NavigationSplitView {
                    TaskListView()
                        .navigationTitle("")
                } detail: {
                    ScheduleGridView()
                        .navigationTitle("")
                }
                .focusable()
                .focusEffectDisabled()
                .onKeyPress(.upArrow) {
                    moveSelectedBlock(by: -15)
                }
                .onKeyPress(.downArrow) {
                    moveSelectedBlock(by: 15)
                }
                .onKeyPress(.delete) {
                    deleteSelectedBlock()
                }
            }
        }
        .task {
            await appState.initialize()
        }
    }

    private func moveSelectedBlock(by minutes: Int) -> KeyPress.Result {
        guard let id = appState.selectedBlockID, let store = appState.scheduleStore else { return .ignored }
        let minMinutes = appState.startHour * 60
        let maxMinutes = appState.endHour * 60

        if var block = store.timeBlocks.first(where: { $0.id == id }) {
            let newStart = block.startTime + minutes
            block.startTime = max(minMinutes, min(newStart, maxMinutes - block.duration))
            try? store.updateTimeBlock(block)
            return .handled
        } else if var block = store.standaloneBlocks.first(where: { $0.id == id }) {
            let newStart = block.startTime + minutes
            block.startTime = max(minMinutes, min(newStart, maxMinutes - block.duration))
            try? store.updateStandaloneBlock(block)
            return .handled
        }
        return .ignored
    }

    private func deleteSelectedBlock() -> KeyPress.Result {
        guard let id = appState.selectedBlockID, let store = appState.scheduleStore else { return .ignored }

        if store.timeBlocks.contains(where: { $0.id == id }) {
            try? store.deleteTimeBlock(id: id)
            appState.selectedBlockID = nil
            return .handled
        } else if store.standaloneBlocks.contains(where: { $0.id == id }) {
            try? store.deleteStandaloneBlock(id: id)
            appState.selectedBlockID = nil
            return .handled
        }
        return .ignored
    }
}
