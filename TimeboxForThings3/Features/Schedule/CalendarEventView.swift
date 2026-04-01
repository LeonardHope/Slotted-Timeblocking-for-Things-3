import SwiftUI

/// A read-only calendar event block with diagonal hatching.
struct CalendarEventView: View {
    let event: CalendarEvent
    @Environment(\.textScale) private var textScale

    private var ppm: CGFloat { Theme.pointsPerMinute }
    private var blockHeight: CGFloat { CGFloat(event.duration) * ppm }
    private var radius: CGFloat { min(8, blockHeight / 6) }
    private var color: Color { .gray }

    var body: some View {
        ZStack(alignment: .leading) {
            // Fill + hatching
            RoundedRectangle(cornerRadius: radius)
                .fill(color.opacity(0.08))
                .overlay(
                    DiagonalStripes(spacing: 6, lineWidth: 1.5)
                        .foregroundStyle(color.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: radius))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: radius)
                        .strokeBorder(color.opacity(0.3), lineWidth: 1)
                )

            // Left accent bar
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color.opacity(0.6))
                    .frame(width: 3)
                    .padding(.vertical, 4)
                Spacer()
            }

            // Content
            Group {
                if event.duration <= 30 {
                    HStack(spacing: 6) {
                        Text(event.title)
                            .font(.system(size: 11 * textScale, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(1)
                        Text(timeRange)
                            .font(.system(size: 9 * textScale))
                            .foregroundStyle(Theme.textTertiary)
                            .lineLimit(1)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(event.title)
                            .font(.system(size: 11 * textScale, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(2)
                        Text(timeRange)
                            .font(.system(size: 9 * textScale))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
            }
            .padding(.leading, 10)
            .padding(.trailing, 6)
        }
        .frame(height: blockHeight)
        .allowsHitTesting(false)
    }

    private var timeRange: String {
        let end = event.startMinutes + event.duration
        return "\(format(event.startMinutes)) – \(format(end))"
    }

    private func format(_ totalMinutes: Int) -> String {
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        let period = h >= 12 ? "pm" : "am"
        let hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h)
        return m == 0 ? "\(hour12)\(period)" : "\(hour12):\(String(format: "%02d", m))\(period)"
    }
}

/// Diagonal stripe pattern.
struct DiagonalStripes: Shape {
    let spacing: CGFloat
    let lineWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let count = Int((rect.width + rect.height) / spacing) + 1
        for i in 0..<count {
            let offset = CGFloat(i) * spacing
            path.move(to: CGPoint(x: offset, y: 0))
            path.addLine(to: CGPoint(x: offset - rect.height, y: rect.height))
        }
        return path.strokedPath(StrokeStyle(lineWidth: lineWidth))
    }
}
