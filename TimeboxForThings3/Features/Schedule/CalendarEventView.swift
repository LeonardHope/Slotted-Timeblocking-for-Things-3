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
        RoundedRectangle(cornerRadius: radius)
            .fill(color.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(color.opacity(0.4), lineWidth: 1)
            )
            .overlay(alignment: .leading) {
                HStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(color)
                        .frame(width: 3)
                        .padding(.vertical, 4)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(event.title)
                            .font(.system(size: 11 * textScale, weight: .medium))
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(event.duration <= 30 ? 1 : 2)
                        if event.duration > 30 {
                            Text(timeRange)
                                .font(.system(size: 10 * textScale))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 4)
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
