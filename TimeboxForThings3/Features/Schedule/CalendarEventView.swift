import SwiftUI

/// A read-only calendar event block on the schedule grid.
struct CalendarEventView: View {
    let event: CalendarEvent
    @Environment(\.textScale) private var textScale

    private var ppm: CGFloat { Theme.pointsPerMinute }
    private var blockHeight: CGFloat { CGFloat(event.duration) * ppm }
    private var radius: CGFloat { min(8, blockHeight / 6) }
    private var color: Color { Color(cgColor: event.calendarColor) }

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: radius)
                .fill(color.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: radius)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        .foregroundStyle(color.opacity(0.35))
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
            VStack(alignment: .leading, spacing: 1) {
                Text(event.title)
                    .font(.system(size: 11 * textScale, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(event.duration <= 30 ? 1 : 2)
                if event.duration > 30 {
                    Text(timeRange)
                        .font(.system(size: 9 * textScale))
                        .foregroundStyle(Theme.textTertiary)
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
