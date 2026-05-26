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

    /// Target slot shown when moving an existing block on the RHS
    var moveTargetMinutes: Int?
    var moveTargetDuration: Int = 30
    var isMovingBlock = false

    func beginDrag(taskUUID: String) {
        isDragging = true
        draggedTaskUUID = taskUUID
    }

    func updateHighlight(minutes: Int?) {
        highlightedSlotMinutes = minutes
    }

    func beginMove(targetMinutes: Int, duration: Int = 30) {
        isMovingBlock = true
        moveTargetMinutes = targetMinutes
        moveTargetDuration = duration
    }

    func updateMove(targetMinutes: Int) {
        moveTargetMinutes = targetMinutes
    }

    func endMove() {
        isMovingBlock = false
        moveTargetMinutes = nil
        moveTargetDuration = 30
    }

    func endDrag() {
        isDragging = false
        draggedTaskUUID = nil
        highlightedSlotMinutes = nil
    }
}
