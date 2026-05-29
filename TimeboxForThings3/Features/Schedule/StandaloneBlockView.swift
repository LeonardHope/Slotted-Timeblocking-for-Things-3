import SwiftUI

struct StandaloneBlockView: View {
    let block: StandaloneBlock
    let onDelete: () -> Void
    let onTitleChange: (String) -> Void
    let onColorCycle: () -> Void
    let onMove: (Int) -> Void
    let onResize: (Int, Int) -> Void

    @State private var isHovering = false
    @State private var isEditing = false
    @State private var editTitle = ""
    @FocusState private var textFieldFocused: Bool
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

    private var blockColor: Color {
        let palette = ProjectColorGenerator.blockPalette
        return palette[block.colorIndex % palette.count]
    }

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

    var body: some View {
        RoundedRectangle(cornerRadius: radius)
            .fill(blockColor.opacity(0.12))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .foregroundStyle(blockColor.opacity(0.4))
            )
            .overlay(alignment: .leading) {
                HStack(spacing: 6) {
                    if isEditing {
                        TextField("Title", text: $editTitle)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12 * textScale))
                            .focused($textFieldFocused)
                            .onSubmit { onTitleChange(editTitle); isEditing = false }
                            .onExitCommand { onTitleChange(editTitle); isEditing = false }
                            .onChange(of: textFieldFocused) {
                                if !textFieldFocused && isEditing {
                                    onTitleChange(editTitle); isEditing = false
                                }
                            }
                            .onAppear { textFieldFocused = true }
                    } else {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(block.title)
                                .font(.system(size: 12 * textScale)).italic()
                                .foregroundStyle(Theme.textPrimary)
                                .onTapGesture(count: 2) { editTitle = block.title; isEditing = true }
                            Text(block.timeRangeDisplay)
                                .font(.system(size: 10 * textScale))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 8)
            }
            .overlay(alignment: .trailing) {
                if isHovering && dragMode == .none {
                    HStack(spacing: 4) {
                        Button(action: onColorCycle) {
                            Circle()
                                .fill(blockColor)
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
            .overlay {
                if appState.selectedBlockID == block.id {
                    RoundedRectangle(cornerRadius: radius).strokeBorder(Color.accentColor, lineWidth: 2)
                }
            }
            .frame(height: visualHeight)
            .offset(y: visualOffset)
            .onHover { isHovering = $0 }
            .onContinuousHover { phase in
                guard dragMode == .none else { return }
                switch phase {
                case .active(let loc):
                    if loc.y < edgeZone || loc.y > blockHeight - edgeZone {
                        NSCursor.resizeUpDown.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                case .ended:
                    NSCursor.arrow.set()
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { appState.selectedBlockID = appState.selectedBlockID == block.id ? nil : block.id }
            .gesture(
                DragGesture(minimumDistance: 3)
                    .onChanged { value in
                        if dragMode == .none {
                            let y = value.startLocation.y
                            if y < edgeZone { dragMode = .resizeTop }
                            else if y > blockHeight - edgeZone { dragMode = .resizeBottom }
                            else { dragMode = .move }
                        }
                        dragTranslation = value.translation.height
                    }
                    .onEnded { value in
                        let mins = (Int(value.translation.height / ppm) / snapGrid) * snapGrid
                        switch dragMode {
                        case .move: onMove(max(0, block.startTime + mins))
                        case .resizeTop:
                            let d = min(mins, block.duration - minDuration)
                            onResize(max(0, block.startTime + d), max(minDuration, block.duration - d))
                        case .resizeBottom:
                            onResize(block.startTime, max(minDuration, block.duration + mins))
                        case .none: break
                        }
                        dragMode = .none; dragTranslation = 0
                    }
            )
    }
}
