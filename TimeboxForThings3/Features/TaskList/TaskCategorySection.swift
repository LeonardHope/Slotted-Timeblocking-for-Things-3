import SwiftUI

/// A collapsible section of tasks for a given category.
struct TaskCategorySection: View {
    let category: TaskCategory
    let tasks: [TaskItem]
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Circle()
                        .fill(categoryColor)
                        .frame(width: Theme.projectDotSize, height: Theme.projectDotSize)

                    Text(category.displayName)
                        .font(Theme.sectionHeader)
                        .foregroundStyle(Theme.textPrimary)

                    if !isExpanded {
                        Text("\(tasks.count)")
                            .font(Theme.metadata)
                            .foregroundStyle(Theme.textTertiary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                }
                .padding(.horizontal, Theme.taskRowHorizontalPadding)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)

            // Tasks
            if isExpanded {
                ForEach(tasks) { task in
                    TaskRowView(task: task)
                }
            }
        }
        .padding(.bottom, 8)
    }

    private var categoryColor: Color {
        switch category {
        case .inbox: Theme.inboxBlue
        case .overdue: Theme.overdueRed
        case .today: Theme.todayGold
        case .upcoming: Theme.upcomingRed
        case .anytime: Theme.anytimeTeal
        case .someday: Theme.somedayAmber
        }
    }
}
