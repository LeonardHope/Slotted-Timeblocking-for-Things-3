import Foundation
import SwiftUI

/// Provider-agnostic project model.
struct ProjectInfo: Identifiable, Hashable {
    let id: String  // UUID
    let title: String
    let areaName: String?

    var color: Color {
        ProjectColorGenerator.color(for: id)
    }
}
