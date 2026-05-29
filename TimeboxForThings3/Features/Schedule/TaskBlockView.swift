import SwiftUI

struct TaskBlockView: View {
    let block: TimeBlock
    let taskItem: TaskItem?
    let onDelete: () -> Void
    let onMove: (Int) -> Void
    let onResize: (Int, Int) -> Void
    let onColorCycle: () -> Void

    @State private var isHovering = false
    @State private var dragMode: DragMode = .none
    @State private var dragTranslation: CGFloat = 0
    @Environment(\.textScale) private var textScale
    @Environment(AppState.self) private var appState

    private let minDuration = 15
    private let snapGrid = 15
    private var ppm: CGFloat { Theme.pointsPerMinute }
    private var blockHeight: CGFloat { CGFloat(block.duration) * ppm }
    private var radius: CGFloat { min(8, blockHeight / 6) }
    private var edgeZone: CGFloat { min(12, blockHeight / 4) }

    private enum DragMode { case none, move, resizeTop, resizeBottom }

    // Computed visual state during drag
    private var visualOffset: CGFloat {
        switch dragMode {
        case .move: return dragTranslation
        case .resizeTop: return min(dragTranslation, CGFloat(block.duration - minDuration) * ppm)
        default: return 0
        }
    }

    private var visualHeight: CGFloat {
        switch dragMode {
        case .resizeTop:
            let delta = min(dragTranslation, CGFloat(block.duration - minDuration) * ppm)
            return max(CGFloat(minDuration) * ppm, blockHeight - delta)
        case .resizeBottom:
            let delta = max(dragTranslation, -CGFloat(block.duration - minDuration) * ppm)
            return max(CGFloat(minDuration) * ppm, blockHeight + delta)
        default:
            return blockHeight
        }
    }

    private var blockColor: Color {
        let palette = ProjectColorGenerator.blockPalette
        if let idx = block.colorIndex {
            return palette[idx % palette.count]
        }
        return taskItem?.projectUUID.map { ProjectColorGenerator.color(for: $0) } ?? .gray
    }

    var body: some View {
        let color = blockColor

        RoundedRectangle(cornerRadius: radius)
            .fill(color.opacity(0.25))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(color.opacity(0.5), lineWidth: 1)
            )
            // Content
            .overlay(alignment: .leading) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(taskItem?.title ?? "Unknown Task")
                        .font(.system(size: 12 * textScale, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(block.duration <= 15 ? 1 : 2)

                    if block.duration > 30, let name = taskItem?.projectName {
                        Text(name)
                            .font(.system(size: 10 * textScale))
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(1)
                    }

                    Text(block.timeRangeDisplay)
                        .font(.system(size: 10 * textScale))
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.horizontal, 8)
            }
            // Color dot + delete button on hover
            .overlay(alignment: .trailing) {
                if isHovering && dragMode == .none {
                    HStack(spacing: 4) {
                        Button(action: onColorCycle) {
                            Circle()
                                .fill(color)
                                .frame(width: 10, height: 10)
                        }
                        .buttonStyle(.plain)
                        Button(action: onDelete) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.trailing, 4)
                }
            }
            // Selection border
            .overlay {
                if appState.selectedBlockID == block.id {
                    RoundedRectangle(cornerRadius: radius)
                        .strokeBorder(Color.accentColor, lineWidth: 2)
                }
            }
            .frame(height: visualHeight)
            .offset(y: visualOffset)
            .onHover { hovering in
                isHovering = hovering
                if !hovering { NSCursor.arrow.set() }
            }
            .onContinuousHover { phase in
                guard dragMode == .none else { return }
                switch phase {
                case .active(let loc):
                    let inTopEdge = loc.y < edgeZone
                    let inBottomEdge = loc.y > blockHeight - edgeZone
                    if inTopEdge || inBottomEdge {
                        NSCursor.resizeUpDown.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                case .ended:
                    NSCursor.arrow.set()
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                appState.selectedBlockID = appState.selectedBlockID == block.id ? nil : block.id
            }
            .gesture(
                DragGesture(minimumDistance: 3)
                    .onChanged { value in
                        if dragMode == .none {
                            // Determine mode from start location
                            let startY = value.startLocation.y
                            if startY < edgeZone {
                                dragMode = .resizeTop
                            } else if startY > blockHeight - edgeZone {
                                dragMode = .resizeBottom
                            } else {
                                dragMode = .move
                            }
                        }
                        dragTranslation = value.translation.height
                    }
                    .onEnded { value in
                        let mins = (Int(value.translation.height / ppm) / snapGrid) * snapGrid
                        switch dragMode {
                        case .move:
                            onMove(max(0, block.startTime + mins))
                        case .resizeTop:
                            let d = min(mins, block.duration - minDuration)
                            onResize(max(0, block.startTime + d), max(minDuration, block.duration - d))
                        case .resizeBottom:
                            onResize(block.startTime, max(minDuration, block.duration + mins))
                        case .none:
                            break
                        }
                        dragMode = .none
                        dragTranslation = 0
                    }
            )
    }
}
