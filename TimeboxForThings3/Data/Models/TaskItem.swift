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

    var hasNotes: Bool { notes != nil && !(notes?.isEmpty ?? true) }
    var hasChecklist: Bool { checklistTotal > 0 }
    var isOverdue: Bool {
        guard let deadline else { return false }
        return deadline < Calendar.current.startOfDay(for: .now)
    }

    var deadlineDisplayText: String? {
        guard let deadline else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let days = calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: deadline)).day ?? 0

        if days < 0 {
            return "\(abs(days))d overdue"
        } else if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Tomorrow"
        } else if days <= 7 {
            return "\(days) days left"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: deadline)
        }
    }
}
