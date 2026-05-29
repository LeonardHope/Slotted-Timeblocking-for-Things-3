import SwiftUI

/// Generates deterministic colors for projects.
///
/// Design philosophy (matching Things 3's restraint):
/// - LHS task list: uniform muted blue-gray dot for all projects
/// - RHS schedule grid: soft desaturated pastels to distinguish projects at a glance
enum ProjectColorGenerator {

    /// Muted blue-gray used for all project dots in the LHS task list.
    /// Matches Things 3's single-color project indicators.
    static let listDotColor = Color(hue: 0.6, saturation: 0.3, brightness: 0.55)

    /// Soft pastel palette for RHS schedule blocks.
    /// Low saturation (15-25%), high brightness — watercolors, not highlighters.
    static let blockPalette: [Color] = [
        Color(hue: 0.60, saturation: 0.20, brightness: 0.85),  // Soft blue
        Color(hue: 0.08, saturation: 0.22, brightness: 0.88),  // Soft peach
        Color(hue: 0.33, saturation: 0.18, brightness: 0.82),  // Soft sage
        Color(hue: 0.80, saturation: 0.18, brightness: 0.85),  // Soft lavender
        Color(hue: 0.48, saturation: 0.20, brightness: 0.82),  // Soft teal
        Color(hue: 0.12, saturation: 0.22, brightness: 0.86),  // Soft amber
        Color(hue: 0.92, saturation: 0.16, brightness: 0.86),  // Soft rose
        Color(hue: 0.55, saturation: 0.15, brightness: 0.83),  // Soft sky
        Color(hue: 0.70, saturation: 0.18, brightness: 0.82),  // Soft indigo
        Color(hue: 0.42, saturation: 0.16, brightness: 0.84),  // Soft mint
        Color(hue: 0.18, saturation: 0.20, brightness: 0.85),  // Soft gold
        Color(hue: 0.02, saturation: 0.18, brightness: 0.86),  // Soft coral
    ]

    /// Deterministic block color for the RHS schedule grid.
    static func color(for identifier: String) -> Color {
        let hash = identifier.utf8.reduce(0) { ($0 &+ Int($1)) &* 31 }
        return blockPalette[abs(hash) % blockPalette.count]
    }
}
