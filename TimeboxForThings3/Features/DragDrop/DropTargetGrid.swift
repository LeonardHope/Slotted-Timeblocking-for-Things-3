import SwiftUI
import UniformTypeIdentifiers

/// NSViewRepresentable that provides drop target with live position tracking
/// and a visual highlight for the target time slot.
struct DropTargetGrid: NSViewRepresentable {
    let startMinutes: Int
    let pointsPerMinute: CGFloat
    let slotHeight: CGFloat
    let timeLabelWidth: CGFloat
    let onDrop: (String, Int) -> Void       // taskUUID, minutes
    let onDoubleClick: (Int) -> Void         // minutes
    let onSingleClick: () -> Void            // deselect blocks

    func makeNSView(context: Context) -> DropTargetNSView {
        let view = DropTargetNSView()
        view.startMinutes = startMinutes
        view.pointsPerMinute = pointsPerMinute
        view.slotHeight = slotHeight
        view.timeLabelWidth = timeLabelWidth
        view.onDrop = onDrop
        view.onDoubleClick = onDoubleClick
        view.onSingleClick = onSingleClick
        view.registerForDraggedTypes([.init(UTType.timeboxTask.identifier)])
        return view
    }

    func updateNSView(_ nsView: DropTargetNSView, context: Context) {
        nsView.startMinutes = startMinutes
        nsView.pointsPerMinute = pointsPerMinute
        nsView.slotHeight = slotHeight
        nsView.timeLabelWidth = timeLabelWidth
        nsView.onDrop = onDrop
        nsView.onDoubleClick = onDoubleClick
        nsView.onSingleClick = onSingleClick
    }
}

class DropTargetNSView: NSView {
    var startMinutes: Int = 0
    var pointsPerMinute: CGFloat = 1.6
    var slotHeight: CGFloat = 48
    var timeLabelWidth: CGFloat = 56
    var onDrop: ((String, Int) -> Void)?
    var onDoubleClick: ((Int) -> Void)?
    var onSingleClick: (() -> Void)?

    private var highlightY: CGFloat?
    private let highlightColor = NSColor.controlAccentColor.withAlphaComponent(0.12)
    private let highlightBorderColor = NSColor.controlAccentColor.withAlphaComponent(0.4)

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let y = highlightY else { return }

        let rect = NSRect(
            x: timeLabelWidth + 4,
            y: y,
            width: bounds.width - timeLabelWidth - 16,
            height: slotHeight
        )
        let path = NSBezierPath(roundedRect: rect, xRadius: 10, yRadius: 10)

        highlightColor.setFill()
        path.fill()

        highlightBorderColor.setStroke()
        path.lineWidth = 1.5
        path.stroke()
    }

    private func minutesFromY(_ y: CGFloat) -> Int {
        startMinutes + Int(y / pointsPerMinute)
    }

    private func snappedY(for point: NSPoint) -> CGFloat {
        let minutes = minutesFromY(point.y)
        let snapped = (minutes / 15) * 15
        return CGFloat(snapped - startMinutes) * pointsPerMinute
    }

    // MARK: - Drag destination

    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        highlightY = snappedY(for: convert(sender.draggingLocation, from: nil))
        needsDisplay = true
        return .copy
    }

    override func draggingUpdated(_ sender: any NSDraggingInfo) -> NSDragOperation {
        highlightY = snappedY(for: convert(sender.draggingLocation, from: nil))
        needsDisplay = true
        return .copy
    }

    override func draggingExited(_ sender: (any NSDraggingInfo)?) {
        highlightY = nil
        needsDisplay = true
    }

    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        highlightY = nil
        needsDisplay = true

        guard let data = sender.draggingPasteboard.data(forType: .init(UTType.timeboxTask.identifier)) else {
            return false
        }
        guard let item = try? JSONDecoder().decode(TaskDragItem.self, from: data) else {
            return false
        }

        let location = convert(sender.draggingLocation, from: nil)
        let minutes = minutesFromY(location.y)
        onDrop?(item.taskUUID, minutes)
        return true
    }

    // MARK: - Double click

    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 1 {
            onSingleClick?()
        } else if event.clickCount == 2 {
            let location = convert(event.locationInWindow, from: nil)
            let minutes = minutesFromY(location.y)
            onDoubleClick?(minutes)
        }
    }
}
