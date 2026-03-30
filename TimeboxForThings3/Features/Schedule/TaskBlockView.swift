import SwiftUI

/// A task block rendered on the schedule grid, with move and resize gestures.
struct TaskBlockView: View {
    let block: TimeBlock
    let taskItem: TaskItem?
    let onDelete: () -> Void
    let onMove: (Int) -> Void       // New startTime in minutes
    let onResize: (Int) -> Void     // New duration in minutes

    @State private var isHovering = false
    @State private var dragOffset: CGFloat = 0
    @State private var resizeOffset: CGFloat = 0

    private let minDuration = 15 // minutes
    private let snapGrid = 15    // minutes

    var body: some View {
        let projectColor = taskItem?.projectUUID.map { ProjectColorGenerator.color(for: $0) } ?? .blue

        ZStack(alignment: .topLeading) {
            // Background
            RoundedRectangle(cornerRadius: 6)
                .fill(projectColor.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(projectColor.opacity(0.4), lineWidth: 1)
                )

            // Left accent bar
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(projectColor)
                    .frame(width: 3)
                    .padding(.vertical, 3)
                Spacer()
            }

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(taskItem?.title ?? "Unknown Task")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)

                if let projectName = taskItem?.projectName {
                    Text(projectName)
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Text(block.timeRangeDisplay)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(.leading, 10)
            .padding(.trailing, 24)
            .padding(.vertical, 4)

            // Delete button (top-right, on hover)
            if isHovering {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: onDelete) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        .buttonStyle(.plain)
                        .padding(4)
                    }
                    Spacer()
                }
            }

            // Bottom resize handle
            VStack {
                Spacer()
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 8)
                    .contentShape(Rectangle())
                    .onHover { inside in
                        if inside { NSCursor.resizeUpDown.push() } else { NSCursor.pop() }
                    }
                    .gesture(resizeGesture)
            }
        }
        .offset(y: dragOffset)
        .onHover { hovering in
            isHovering = hovering
        }
        .contentShape(Rectangle())
        .gesture(moveGesture)
    }

    // MARK: - Move gesture (drag the block body)

    private var moveGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation.height
            }
            .onEnded { value in
                let minutesDelta = Int(value.translation.height / Theme.pointsPerMinute)
                let snappedDelta = (minutesDelta / snapGrid) * snapGrid
                let newStart = max(0, block.startTime + snappedDelta)
                dragOffset = 0
                onMove(newStart)
            }
    }

    // MARK: - Resize gesture (drag bottom edge)

    private var resizeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                resizeOffset = value.translation.height
            }
            .onEnded { value in
                let minutesDelta = Int(value.translation.height / Theme.pointsPerMinute)
                let snappedDelta = (minutesDelta / snapGrid) * snapGrid
                let newDuration = max(minDuration, block.duration + snappedDelta)
                resizeOffset = 0
                onResize(newDuration)
            }
    }
}
