import SwiftUI
import UniformTypeIdentifiers

/// Transferable item representing a task being dragged from the LHS.
struct TaskDragItem: Codable, Transferable {
    let taskUUID: String
    let title: String

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .timeboxTask)
    }
}

extension UTType {
    static let timeboxTask = UTType(exportedAs: "com.timebox.task-item")
}

/// Shared state for drag operations across panels.
@Observable
@MainActor
final class DragDropCoordinator {
    var isDragging = false
    var draggedTaskUUID: String?
    var highlightedSlotMinutes: Int?

    func beginDrag(taskUUID: String) {
        isDragging = true
        draggedTaskUUID = taskUUID
    }

    func updateHighlight(minutes: Int?) {
        highlightedSlotMinutes = minutes
    }

    func endDrag() {
        isDragging = false
        draggedTaskUUID = nil
        highlightedSlotMinutes = nil
    }
}
