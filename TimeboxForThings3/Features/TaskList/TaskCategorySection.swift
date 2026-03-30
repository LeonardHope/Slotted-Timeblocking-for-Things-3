import SwiftUI

/// A collapsible section of tasks for a given category,
/// with tasks grouped by project (matching Things 3's presentation).
struct TaskCategorySection: View {
    let category: TaskCategory
    let tasks: [TaskItem]
    @State private var isExpanded = true
    @Environment(\.textScale) private var textScale

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            HStack(spacing: 6) {
                Image(systemName: categoryIcon)
                    .font(.system(size: 14 * textScale, weight: .medium))
                    .foregroundStyle(categoryColor)
                    .frame(width: 20)

                Text(category.displayName)
                    .font(Theme.sectionHeader(scale: textScale))
                    .foregroundStyle(Theme.textPrimary)

                Text("\(tasks.count)")
                    .font(Theme.metadata(scale: textScale))
                    .foregroundStyle(Theme.textTertiary)

                Spacer()

                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(.horizontal, Theme.taskRowHorizontalPadding)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }

            // Tasks grouped by project
            if isExpanded {
                let grouped = groupByProject(tasks)
                ForEach(grouped, id: \.projectName) { group in
                    // Project sub-header (only if task has a project)
                    if let projectName = group.projectName {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(ProjectColorGenerator.listDotColor)
                                .frame(width: 8, height: 8)
                            Text(projectName)
                                .font(Theme.metadata(scale: textScale))
                                .foregroundStyle(Theme.textSecondary)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, Theme.taskRowHorizontalPadding + 4)
                        .padding(.top, 8)
                        .padding(.bottom, 2)
                    }

                    ForEach(group.tasks) { task in
                        TaskRowView(task: task)
                    }
                }
            }
        }
        .padding(.bottom, 8)
    }

    // MARK: - Project grouping

    private struct ProjectGroup: Identifiable {
        let projectName: String?
        let projectUUID: String?
        let tasks: [TaskItem]
        var id: String { projectName ?? "__no_project__" }
    }

    private func groupByProject(_ tasks: [TaskItem]) -> [ProjectGroup] {
        var groups: [(name: String?, uuid: String?, tasks: [TaskItem])] = []
        var seen: [String: Int] = [:] // projectName -> index in groups

        for task in tasks {
            let key = task.projectName ?? "__no_project__"
            if let idx = seen[key] {
                groups[idx].tasks.append(task)
            } else {
                seen[key] = groups.count
                groups.append((name: task.projectName, uuid: task.projectUUID, tasks: [task]))
            }
        }

        return groups.map { ProjectGroup(projectName: $0.name, projectUUID: $0.uuid, tasks: $0.tasks) }
    }

    // MARK: - Category styling

    private var categoryIcon: String {
        switch category {
        case .inbox: "tray.fill"
        case .today: "star.fill"
        case .upcoming: "calendar"
        case .anytime: "circle.circle.fill"
        case .someday: "archivebox.fill"
        }
    }

    private var categoryColor: Color {
        switch category {
        case .inbox: Theme.inboxBlue
        case .today: Theme.todayGold
        case .upcoming: Theme.upcomingRed
        case .anytime: Theme.anytimeTeal
        case .someday: Theme.somedayAmber
        }
    }
}
