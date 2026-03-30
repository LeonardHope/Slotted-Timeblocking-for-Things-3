import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: 0) {
            // LHS — Task List
            TaskListView()
                .frame(minWidth: 280, idealWidth: 320, maxWidth: 450)

            Divider()

            // RHS — Schedule Grid
            ScheduleGridView()
                .frame(minWidth: 400, idealWidth: 500, maxWidth: .infinity)
        }
        .task {
            await appState.initialize()
        }
    }
}
