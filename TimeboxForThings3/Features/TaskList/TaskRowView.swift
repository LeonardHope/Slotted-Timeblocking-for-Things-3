import SwiftUI

/// A single task row in the LHS list — minimal style matching Things 3.
/// Shows a subtle rounded rectangle on hover, and a styled drag preview.
struct TaskRowView: View {
    let task: TaskItem
    @State private var isHovering = false
    @Environment(\.textScale) private var textScale

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(Theme.taskTitle(scale: textScale))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)

                // Project name omitted — shown in project group header above
            }

            Spacer()

            if let deadlineText = task.deadlineDisplayText {
                Text(deadlineText)
                    .font(Theme.metadata(scale: textScale))
                    .foregroundStyle(task.isOverdue ? Theme.overdueRed : Theme.textTertiary)
            }
        }
        .padding(.horizontal, Theme.taskRowHorizontalPadding)
        .padding(.vertical, Theme.taskRowVerticalPadding)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovering ? Theme.textPrimary.opacity(0.06) : Color.clear)
        )
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
        .draggable(TaskDragItem(taskUUID: task.id, title: task.title)) {
            HStack(spacing: 8) {
                if let projectUUID = task.projectUUID {
                    Circle()
                        .fill(ProjectColorGenerator.color(for: projectUUID))
                        .frame(width: 8, height: 8)
                }
                Text(task.title)
                    .font(Theme.taskTitle(scale: textScale))
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Theme.contentBackground)
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
            )
        }
    }
}
