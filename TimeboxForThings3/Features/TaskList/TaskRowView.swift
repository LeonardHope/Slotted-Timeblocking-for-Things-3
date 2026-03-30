import SwiftUI

/// A single task row in the LHS list — minimal style matching Things 3.
struct TaskRowView: View {
    let task: TaskItem

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Task content
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(Theme.taskTitle)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)

                // Project name
                if let projectName = task.projectName {
                    HStack(spacing: 4) {
                        if let projectUUID = task.projectUUID {
                            Circle()
                                .fill(ProjectColorGenerator.color(for: projectUUID))
                                .frame(width: 6, height: 6)
                        }
                        Text(projectName)
                            .font(Theme.metadata)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }

            Spacer()

            // Deadline
            if let deadlineText = task.deadlineDisplayText {
                Text(deadlineText)
                    .font(Theme.metadata)
                    .foregroundStyle(task.isOverdue ? Theme.overdueRed : Theme.textTertiary)
            }
        }
        .padding(.horizontal, Theme.taskRowHorizontalPadding)
        .padding(.vertical, Theme.taskRowVerticalPadding)
        .contentShape(Rectangle())
        .draggable(TaskDragItem(taskUUID: task.id, title: task.title))
    }
}
