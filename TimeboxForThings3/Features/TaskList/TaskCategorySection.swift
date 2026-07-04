import SwiftUI

/// A collapsible section of tasks grouped by Area > Project.
struct TaskCategorySection: View {
    let category: TaskCategory
    let tasks: [TaskItem]
    @State private var isExpanded: Bool = false
    @State private var expandedAreas: Set<String> = []
    @State private var expandedProjects: Set<String> = []
    @State private var didSetDefaults = false
    @Environment(\.textScale) private var textScale
    @Environment(AppState.self) private var appState

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
                let hideEmpty = appState.hideEmptyProjects
                ForEach(hierarchy) { areaGroup in
                    let visibleProjects = hideEmpty
                        ? areaGroup.projects.filter { !$0.tasks.isEmpty }
                        : areaGroup.projects

                    if !hideEmpty || !visibleProjects.isEmpty {
                        // Tasks with no area collect under an "Unassigned" header, so
                        // every task sits beneath a toggleable group header consistent
                        // with the named-area sections.
                        areaHeader(areaGroup.areaName ?? "Unassigned", key: areaGroup.id)

                        if expandedAreas.contains(areaGroup.id) {
                            ForEach(visibleProjects) { projectGroup in
                                if let projectName = projectGroup.projectName {
                                    projectHeader(projectName, key: projectGroup.id, indented: true)
                                }

                                // Tasks with no project render directly under their area
                                // header, so they must always show when the area is
                                // expanded rather than gate on a non-existent toggle.
                                if projectGroup.projectName == nil || expandedProjects.contains(projectGroup.id) {
                                    ForEach(projectGroup.tasks) { task in
                                        TaskRowView(task: task)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.bottom, 8)
        .onAppear {
            guard !didSetDefaults else { return }
            didSetDefaults = true
            if category == .today || category == .inbox {
                isExpanded = true
                let hierarchy = buildHierarchy(tasks)
                for area in hierarchy { expandedAreas.insert(area.id) }
                for area in hierarchy {
                    for project in area.projects { expandedProjects.insert(project.id) }
                }
            }
        }
    }

    // MARK: - Headers

    private func areaHeader(_ name: String, key: String) -> some View {
        let expanded = expandedAreas.contains(key)
        return HStack(spacing: 6) {
            Image(systemName: expanded ? "chevron.down" : "chevron.right")
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
                if expanded { expandedAreas.remove(key) } else { expandedAreas.insert(key) }
            }
        }
    }

    private func projectHeader(_ name: String, key: String, indented: Bool) -> some View {
        let expanded = expandedProjects.contains(key)
        return HStack(spacing: 6) {
            Circle()
                .fill(ProjectColorGenerator.listDotColor)
                .frame(width: 8, height: 8)
            Text(name)
                .font(Theme.metadata(scale: textScale))
                .foregroundStyle(Theme.textSecondary)
                .fontWeight(.medium)
            Spacer()
            Image(systemName: expanded ? "chevron.down" : "chevron.right")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(.horizontal, Theme.taskRowHorizontalPadding + (indented ? 16 : 4))
        .padding(.top, 6)
        .padding(.bottom, 2)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.15)) {
                if expanded { expandedProjects.remove(key) } else { expandedProjects.insert(key) }
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

        // Loose (ungrouped) tasks render without a header, so they must lead —
        // matching Things 3, where items with no area/project sit at the top of a
        // list. Sorting them last would append them under the final area's tasks,
        // making them read as part of that area.
        let sortedAreas = areaOrder.sorted { a, b in
            if a == "__no_area__" { return true }
            if b == "__no_area__" { return false }
            return a.localizedCaseInsensitiveCompare(b) == .orderedAscending
        }

        return sortedAreas.map { areaKey in
            let sortedProjects = (projectOrder[areaKey] ?? []).sorted { a, b in
                if a == "__no_project__" { return true }
                if b == "__no_project__" { return false }
                return a.localizedCaseInsensitiveCompare(b) == .orderedAscending
            }
            let projects = sortedProjects.map { projectKey in
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
