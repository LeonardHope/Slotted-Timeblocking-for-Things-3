import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationSplitView {
            // LHS — Task List (sidebar)
            TaskListView()
        } detail: {
            // RHS — Schedule Grid
            ScheduleGridView()
        }
        .task {
            await appState.initialize()
        }
    }
}
