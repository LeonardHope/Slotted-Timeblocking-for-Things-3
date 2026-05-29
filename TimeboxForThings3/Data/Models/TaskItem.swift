import Foundation

/// Provider-agnostic task model used by the UI layer.
struct TaskItem: Identifiable, Hashable {
    let id: String          // UUID from source
    let title: String
    let notes: String?
    let projectName: String?
    let projectUUID: String?
    let areaName: String?
    let headingName: String?
    let tags: [String]
    let startDate: Date?
    let deadline: Date?
    let creationDate: Date?
    let todayIndex: Int
    let startValue: Int     // 0=Inbox, 1=Anytime, 2=Someday
    let checklistTotal: Int
    let checklistOpen: Int

    var isOverdue: Bool {
        guard let deadline else { return false }
        return deadline < Calendar.current.startOfDay(for: .now)
    }

    private static nonisolated(unsafe) let relativeDateFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f
    }()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    var deadlineDisplayText: String? {
        guard let deadline else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let deadlineDay = calendar.startOfDay(for: deadline)
        let days = calendar.dateComponents([.day], from: today, to: deadlineDay).day ?? 0

        if days < 0 {
            return Self.relativeDateFormatter.localizedString(for: deadlineDay, relativeTo: today)
        } else if days <= 7 {
            return Self.relativeDateFormatter.localizedString(for: deadlineDay, relativeTo: today)
        } else {
            return Self.dateFormatter.string(from: deadline)
        }
    }
}
