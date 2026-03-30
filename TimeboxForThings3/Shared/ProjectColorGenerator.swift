import SwiftUI

/// Generates deterministic colors for projects based on their UUID.
/// Uses a curated palette of soft, muted tones inspired by Things 3.
enum ProjectColorGenerator {
    static let palette: [Color] = [
        Color(hue: 0.58, saturation: 0.50, brightness: 0.75),  // Blue
        Color(hue: 0.08, saturation: 0.55, brightness: 0.85),  // Orange
        Color(hue: 0.33, saturation: 0.45, brightness: 0.70),  // Green
        Color(hue: 0.82, saturation: 0.40, brightness: 0.75),  // Purple
        Color(hue: 0.00, saturation: 0.50, brightness: 0.80),  // Red
        Color(hue: 0.47, saturation: 0.45, brightness: 0.72),  // Teal
        Color(hue: 0.13, saturation: 0.50, brightness: 0.80),  // Amber
        Color(hue: 0.70, saturation: 0.35, brightness: 0.78),  // Indigo
        Color(hue: 0.92, saturation: 0.40, brightness: 0.78),  // Pink
        Color(hue: 0.42, saturation: 0.40, brightness: 0.68),  // Cyan
        Color(hue: 0.18, saturation: 0.45, brightness: 0.75),  // Gold
        Color(hue: 0.55, saturation: 0.35, brightness: 0.80),  // Sky
    ]

    static func color(for identifier: String) -> Color {
        let hash = identifier.utf8.reduce(0) { ($0 &+ Int($1)) &* 31 }
        return palette[abs(hash) % palette.count]
    }

    static func colorIndex(for identifier: String) -> Int {
        let hash = identifier.utf8.reduce(0) { ($0 &+ Int($1)) &* 31 }
        return abs(hash) % palette.count
    }
}
