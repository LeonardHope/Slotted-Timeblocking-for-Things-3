import SwiftUI

/// Things 3-inspired design tokens.
enum Theme {
    // MARK: - Typography
    static let pageTitle: Font = .system(size: 24, weight: .bold)
    static let sectionHeader: Font = .system(size: 15, weight: .semibold)
    static let taskTitle: Font = .system(size: 14, weight: .regular)
    static let metadata: Font = .system(size: 12, weight: .regular)
    static let metadataSemibold: Font = .system(size: 12, weight: .semibold)

    // MARK: - Colors
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary = Color(nsColor: .tertiaryLabelColor)
    static let background = Color(nsColor: .windowBackgroundColor)
    static let contentBackground = Color(nsColor: .textBackgroundColor)
    static let sidebarBackground = Color(nsColor: .controlBackgroundColor)
    static let overdueRed = Color.red
    static let nowLineRed = Color.red

    // Sidebar navigation icon colors (matching Things 3)
    static let inboxBlue = Color(hue: 0.58, saturation: 0.65, brightness: 0.80)
    static let todayGold = Color(hue: 0.12, saturation: 0.70, brightness: 0.90)
    static let upcomingRed = Color(hue: 0.02, saturation: 0.65, brightness: 0.85)
    static let anytimeTeal = Color(hue: 0.50, saturation: 0.50, brightness: 0.75)
    static let somedayAmber = Color(hue: 0.10, saturation: 0.45, brightness: 0.80)

    // MARK: - Spacing
    static let taskRowVerticalPadding: CGFloat = 8
    static let taskRowHorizontalPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 24
    static let checkboxSize: CGFloat = 18
    static let checkboxStrokeWidth: CGFloat = 1.5
    static let projectDotSize: CGFloat = 10

    // MARK: - Grid
    static let slotHeight: CGFloat = 48       // Height of a 30-min slot
    static let pointsPerMinute: CGFloat = 48.0 / 30.0  // 1.6
    static let timeLabelWidth: CGFloat = 56
    static let gridLineColor = Color(nsColor: .separatorColor)
}
