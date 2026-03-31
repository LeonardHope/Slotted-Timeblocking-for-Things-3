import Foundation

/// Categories matching Things 3's built-in lists.
/// See: https://culturedcode.com/things/support/articles/4001304/
enum TaskCategory: Int, CaseIterable, Identifiable {
    case inbox
    case today
    case upcoming
    case anytime
    case someday

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .inbox: "Inbox"
        case .today: "Today"
        case .upcoming: "Upcoming"
        case .anytime: "Anytime"
        case .someday: "Someday"
        }
    }
}

/// Categorizes tasks using Things 3's rules:
/// - startDate takes priority over the start field
/// - A task with a future startDate is always Upcoming, even if start=2
/// - A task with startDate <= today or deadline <= today is Today
/// - Inbox: start=0
/// - Someday: start=2 with no startDate
/// - Anytime: start=1 with no startDate and no past deadline
enum TaskCategorizer {
    static func categorize(_ task: TaskItem, referenceDate: Date = .now) -> TaskCategory {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: referenceDate)

        // Inbox: unprocessed tasks
        if task.startValue == 0 { return .inbox }

        // startDate takes priority over start field
        if let startDate = task.startDate {
            let start = calendar.startOfDay(for: startDate)
            if start > today {
                return .upcoming
            }
            // startDate is today or earlier → Today
            return .today
        }

        // No startDate — check deadline
        if let deadline = task.deadline {
            let dl = calendar.startOfDay(for: deadline)
            if dl <= today {
                return .today
            }
        }

        // No startDate, no past deadline — use start field
        if task.startValue == 2 { return .someday }

        // start=1, no dates → Anytime
        return .anytime
    }

    /// Sort tasks: start date first, then deadline, then tasks without dates last (alphabetically).
    static func sortTasks(_ tasks: [TaskItem]) -> [TaskItem] {
        tasks.sorted { a, b in
            let aHasDate = a.startDate != nil || a.deadline != nil
            let bHasDate = b.startDate != nil || b.deadline != nil

            // Tasks with dates come before tasks without
            if aHasDate != bHasDate { return aHasDate }

            // Both have no dates — alphabetical
            if !aHasDate && !bHasDate {
                return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
            }

            // Both have dates — sort by start date first, then deadline
            let aDate = a.startDate ?? a.deadline ?? .distantFuture
            let bDate = b.startDate ?? b.deadline ?? .distantFuture
            if aDate != bDate { return aDate < bDate }

            // Same start date — sort by deadline
            let aDeadline = a.deadline ?? .distantFuture
            let bDeadline = b.deadline ?? .distantFuture
            if aDeadline != bDeadline { return aDeadline < bDeadline }

            return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
        }
    }

    static func groupByCategory(_ tasks: [TaskItem], referenceDate: Date = .now) -> [(category: TaskCategory, tasks: [TaskItem])] {
        var groups: [TaskCategory: [TaskItem]] = [:]
        for task in tasks {
            let category = categorize(task, referenceDate: referenceDate)
            groups[category, default: []].append(task)
        }
        // Things 3 behavior: Anytime includes Today tasks (shown with a star in Things)
        if let todayTasks = groups[.today], !todayTasks.isEmpty {
            groups[.anytime, default: []].insert(contentsOf: todayTasks, at: 0)
        }
        return TaskCategory.allCases.compactMap { category in
            guard var tasks = groups[category], !tasks.isEmpty else { return nil }
            tasks = sortTasks(tasks)
            return (category: category, tasks: tasks)
        }
    }
}
