import SwiftUI

/// Things 3-inspired design tokens.
enum Theme {
    // MARK: - Typography (SF Pro Text / Display)
    static func pageTitle(scale: Double = 1.0) -> Font {
        .system(size: 24 * scale, weight: .bold, design: .default)
    }
    static func sectionHeader(scale: Double = 1.0) -> Font {
        .system(size: 15 * scale, weight: .semibold, design: .default)
    }
    static func taskTitle(scale: Double = 1.0) -> Font {
        .system(size: 14 * scale, weight: .regular, design: .default)
    }
    static func metadata(scale: Double = 1.0) -> Font {
        .system(size: 12 * scale, weight: .regular, design: .default)
    }
    static func metadataSemibold(scale: Double = 1.0) -> Font {
        .system(size: 12 * scale, weight: .semibold, design: .default)
    }

    // Static versions at default scale
    static let pageTitle: Font = .system(size: 24, weight: .bold, design: .default)
    static let sectionHeader: Font = .system(size: 15, weight: .semibold, design: .default)
    static let taskTitle: Font = .system(size: 14, weight: .regular, design: .default)
    static let metadata: Font = .system(size: 12, weight: .regular, design: .default)
    static let metadataSemibold: Font = .system(size: 12, weight: .semibold, design: .default)

    // MARK: - Colors
    // Things 3 uses a sidebar that's slightly darker than the main content area
    // in both light and dark modes.
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary = Color(nsColor: .tertiaryLabelColor)

    // LHS task list — matches Things 3 sidebar: rgb(41,41,41) dark, warm off-white light
    static let listBackground = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
            ? NSColor(red: 41/255, green: 41/255, blue: 41/255, alpha: 1.0)
            : NSColor(red: 248/255, green: 248/255, blue: 249/255, alpha: 1.0)
    })
    // RHS content area — matches Things 3 content
    static let contentBackground = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
            ? NSColor(red: 44/255, green: 44/255, blue: 45/255, alpha: 1.0)
            : NSColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0)
    })

    static let overdueRed = Color.red
    static let nowLineRed = Color.red

    // Things 3 nav icon colors (from screenshots)
    // Light: gold star, red calendar, teal dots, amber clock
    // Dark: same colors but slightly muted
    static let inboxBlue = Color(red: 0.33, green: 0.55, blue: 0.93)
    static let todayGold = Color(red: 0.95, green: 0.75, blue: 0.25)
    static let upcomingRed = Color(red: 0.90, green: 0.42, blue: 0.35)
    static let anytimeTeal = Color(red: 0.35, green: 0.72, blue: 0.78)
    static let somedayAmber = Color(red: 0.82, green: 0.68, blue: 0.45)

    // MARK: - Spacing
    static let taskRowVerticalPadding: CGFloat = 8
    static let taskRowHorizontalPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 24
    static let checkboxSize: CGFloat = 18
    static let checkboxStrokeWidth: CGFloat = 1.5
    static let projectDotSize: CGFloat = 10

    // MARK: - Grid
    static let slotHeight: CGFloat = 48
    static let pointsPerMinute: CGFloat = 48.0 / 30.0
    static let timeLabelWidth: CGFloat = 56
    static let gridLineColor = Color(nsColor: .separatorColor)
}
