import SwiftUI

/// LHS panel: scrollable list of tasks grouped by category.
struct TaskListView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text("Tasks")
                        .font(Theme.pageTitle)
                    Spacer()
                }
                .padding(.horizontal, Theme.taskRowHorizontalPadding)
                .padding(.bottom, 12)

                if appState.taskProvider.isLoading {
                    ProgressView("Loading Things 3...")
                        .frame(maxWidth: .infinity, minHeight: 100)
                } else if let error = appState.taskProvider.error {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title2)
                            .foregroundStyle(Theme.overdueRed)
                        Text(error.localizedDescription)
                            .font(Theme.metadata)
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 100)
                } else if appState.taskProvider.tasks.isEmpty {
                    Text("No tasks found in Things 3")
                        .font(Theme.metadata)
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 100)
                } else {
                    let grouped = TaskCategorizer.groupByCategory(appState.taskProvider.tasks)
                    ForEach(grouped, id: \.category) { group in
                        TaskCategorySection(
                            category: group.category,
                            tasks: group.tasks
                        )
                    }
                }
            }
            .padding(.vertical, 16)
        }
        .background(Theme.contentBackground)
    }
}
