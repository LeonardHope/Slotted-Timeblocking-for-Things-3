import SwiftUI

/// A standalone (non-task) time block rendered on the schedule grid.
struct StandaloneBlockView: View {
    let block: StandaloneBlock
    let onDelete: () -> Void
    let onTitleChange: (String) -> Void
    let onColorCycle: () -> Void
    let onMove: (Int) -> Void
    let onResize: (Int) -> Void

    @State private var isHovering = false
    @State private var isEditing = false
    @State private var editTitle: String = ""
    @State private var dragOffset: CGFloat = 0

    private let minDuration = 15
    private let snapGrid = 15

    private static let blockColors: [Color] = [
        .blue, .green, .orange, .purple, .pink, .teal, .red, .yellow, .indigo, .mint
    ]

    private var blockColor: Color {
        Self.blockColors[block.colorIndex % Self.blockColors.count]
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background with dotted left border
            RoundedRectangle(cornerRadius: 6)
                .fill(blockColor.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        .foregroundStyle(blockColor.opacity(0.3))
                )

            // Content
            HStack(spacing: 6) {
                // Color dot
                Button(action: onColorCycle) {
                    Circle()
                        .fill(blockColor)
                        .frame(width: 8, height: 8)
                }
                .buttonStyle(.plain)

                if isEditing {
                    TextField("Title", text: $editTitle, onCommit: {
                        onTitleChange(editTitle)
                        isEditing = false
                    })
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .regular))
                } else {
                    Text(block.title)
                        .font(.system(size: 12, weight: .regular))
                        .italic()
                        .foregroundStyle(Theme.textPrimary)
                        .onTapGesture(count: 2) {
                            editTitle = block.title
                            isEditing = true
                        }
                }

                Spacer(minLength: 0)

                Text(block.timeRangeDisplay)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(.horizontal, 8)
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

    private var resizeGesture: some Gesture {
        DragGesture()
            .onChanged { _ in }
            .onEnded { value in
                let minutesDelta = Int(value.translation.height / Theme.pointsPerMinute)
                let snappedDelta = (minutesDelta / snapGrid) * snapGrid
                let newDuration = max(minDuration, block.duration + snappedDelta)
                onResize(newDuration)
            }
    }
}
