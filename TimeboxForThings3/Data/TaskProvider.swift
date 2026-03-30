import Foundation

/// Protocol abstracting the task data source.
/// Implementations: Things3Provider (now), TodoistProvider (future), etc.
@MainActor
protocol TaskProvider: AnyObject, Observable {
    var tasks: [TaskItem] { get }
    var projects: [ProjectInfo] { get }
    var tags: [TagInfo] { get }
    var isLoading: Bool { get }
    var error: Error? { get }

    func startObserving() async
    func stopObserving()
    func refresh() async
}
