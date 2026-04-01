import SwiftUI

/// A collapsible section of tasks grouped by Area > Project.
struct TaskCategorySection: View {
    let category: TaskCategory
    let tasks: [TaskItem]
    @State private var isExpanded = true
    @State private var collapsedAreas: Set<String> = []
    @State private var collapsedProjects: Set<String> = []
    @Environment(\.textScale) private var textScale

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Category header
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
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            }

            if isExpanded {
                let hierarchy = buildHierarchy(tasks)
                ForEach(hierarchy) { areaGroup in
                    // Area header (if named)
                    if let areaName = areaGroup.areaName {
                        areaHeader(areaName, key: areaGroup.id)
                    }

                    if !collapsedAreas.contains(areaGroup.id) {
                        ForEach(areaGroup.projects) { projectGroup in
                            // Project header (if named)
                            if let projectName = projectGroup.projectName {
                                projectHeader(projectName, key: projectGroup.id, indented: areaGroup.areaName != nil)
                            }

                            if !collapsedProjects.contains(projectGroup.id) {
                                ForEach(projectGroup.tasks) { task in
                                    TaskRowView(task: task)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.bottom, 8)
    }

    // MARK: - Headers

    private func areaHeader(_ name: String, key: String) -> some View {
        let collapsed = collapsedAreas.contains(key)
        return HStack(spacing: 6) {
            Image(systemName: collapsed ? "chevron.right" : "chevron.down")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
            Text(name)
                .font(.system(size: 11 * textScale, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.horizontal, Theme.taskRowHorizontalPadding + 4)
        .padding(.top, 10)
        .padding(.bottom, 2)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.15)) {
                if collapsed { collapsedAreas.remove(key) } else { collapsedAreas.insert(key) }
            }
        }
    }

    private func projectHeader(_ name: String, key: String, indented: Bool) -> some View {
        let collapsed = collapsedProjects.contains(key)
        return HStack(spacing: 6) {
            Circle()
                .fill(ProjectColorGenerator.listDotColor)
                .frame(width: 8, height: 8)
            Text(name)
                .font(Theme.metadata(scale: textScale))
                .foregroundStyle(Theme.textSecondary)
                .fontWeight(.medium)
            Spacer()
            Image(systemName: collapsed ? "chevron.right" : "chevron.down")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(.horizontal, Theme.taskRowHorizontalPadding + (indented ? 16 : 4))
        .padding(.top, 6)
        .padding(.bottom, 2)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.15)) {
                if collapsed { collapsedProjects.remove(key) } else { collapsedProjects.insert(key) }
            }
        }
    }

    // MARK: - Hierarchy

    private struct AreaGroup: Identifiable {
        let areaName: String?
        let projects: [ProjectGroup]
        var id: String { areaName ?? "__no_area__" }
    }

    private struct ProjectGroup: Identifiable {
        let projectName: String?
        let tasks: [TaskItem]
        var id: String { projectName ?? "__no_project__" }
    }

    private func buildHierarchy(_ tasks: [TaskItem]) -> [AreaGroup] {
        // Group tasks by area, then by project within each area
        var areaOrder: [String] = []
        var areaMap: [String: [String: [TaskItem]]] = [:] // areaKey -> projectKey -> tasks
        var projectOrder: [String: [String]] = [:] // areaKey -> [projectKeys in order]

        for task in tasks {
            let areaKey = task.areaName ?? "__no_area__"
            let projectKey = task.projectName ?? "__no_project__"

            if areaMap[areaKey] == nil {
                areaOrder.append(areaKey)
                areaMap[areaKey] = [:]
                projectOrder[areaKey] = []
            }
            if areaMap[areaKey]![projectKey] == nil {
                projectOrder[areaKey]!.append(projectKey)
                areaMap[areaKey]![projectKey] = []
            }
            areaMap[areaKey]![projectKey]!.append(task)
        }

        return areaOrder.map { areaKey in
            let projects = (projectOrder[areaKey] ?? []).map { projectKey in
                ProjectGroup(
                    projectName: projectKey == "__no_project__" ? nil : projectKey,
                    tasks: areaMap[areaKey]?[projectKey] ?? []
                )
            }
            return AreaGroup(
                areaName: areaKey == "__no_area__" ? nil : areaKey,
                projects: projects
            )
        }
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
