import Foundation

/// Categories matching Things 3's built-in lists.
enum TaskCategory: Int, CaseIterable, Identifiable {
    case inbox
    case overdue
    case today
    case upcoming
    case anytime
    case someday

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .inbox: "Inbox"
        case .overdue: "Overdue"
        case .today: "Today"
        case .upcoming: "Upcoming"
        case .anytime: "Anytime"
        case .someday: "Someday"
        }
    }
}

enum TaskCategorizer {
    static func categorize(_ task: TaskItem, referenceDate: Date = .now) -> TaskCategory {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: referenceDate)

        // Inbox: start == 0
        if task.startValue == 0 { return .inbox }

        // Someday: start == 2
        if task.startValue == 2 { return .someday }

        // start == 1 (Anytime)

        // Overdue: deadline is before today
        if let deadline = task.deadline, calendar.startOfDay(for: deadline) < today {
            return .overdue
        }

        // Today: startDate is today, or todayIndex is set
        if let startDate = task.startDate {
            let start = calendar.startOfDay(for: startDate)
            if start <= today {
                return .today
            }
            // Future startDate → Upcoming
            return .upcoming
        }

        // No startDate but has todayIndex → Today
        if task.todayIndex >= 0 {
            return .today
        }

        // Anytime: no date, not in Today
        return .anytime
    }

    static func groupByCategory(_ tasks: [TaskItem], referenceDate: Date = .now) -> [(category: TaskCategory, tasks: [TaskItem])] {
        var groups: [TaskCategory: [TaskItem]] = [:]
        for task in tasks {
            let category = categorize(task, referenceDate: referenceDate)
            groups[category, default: []].append(task)
        }
        return TaskCategory.allCases.compactMap { category in
            guard let tasks = groups[category], !tasks.isEmpty else { return nil }
            return (category: category, tasks: tasks)
        }
    }
}
