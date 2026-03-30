import Foundation

/// Provider-agnostic tag model.
struct TagInfo: Identifiable, Hashable {
    let id: String  // UUID
    let title: String
    let shortcut: String?
}
