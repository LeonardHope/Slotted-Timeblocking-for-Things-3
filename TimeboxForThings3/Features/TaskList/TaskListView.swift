import SwiftUI

/// LHS panel: scrollable list of tasks grouped by category.
struct TaskListView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {

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
                    // Filter out tasks that are already scheduled on the RHS
                    let scheduled = appState.scheduledTaskUUIDs
                    let unscheduled = appState.taskProvider.tasks.filter { !scheduled.contains($0.id) }
                    let grouped = TaskCategorizer.groupByCategory(unscheduled)
                    if appState.hideEmptyCategories {
                        ForEach(grouped, id: \.category) { group in
                            TaskCategorySection(
                                category: group.category,
                                tasks: group.tasks
                            )
                        }
                    } else {
                        ForEach(TaskCategory.allCases) { category in
                            let tasks = grouped.first(where: { $0.category == category })?.tasks ?? []
                            TaskCategorySection(
                                category: category,
                                tasks: tasks
                            )
                        }
                    }
                }
            }
            .padding(.vertical, 16)
        }
        .background(Theme.listBackground)
    }
}
