import SwiftUI

/// A calendar event rendered as a background band on the schedule grid.
struct CalendarEventView: View {
    let event: CalendarEvent
    @Environment(\.textScale) private var textScale

    private var ppm: CGFloat { Theme.pointsPerMinute }
    private var blockHeight: CGFloat { CGFloat(event.duration) * ppm }
    private var color: Color { Color(cgColor: event.calendarColor) }

    var body: some View {
        ZStack(alignment: .leading) {
            // Background band
            Rectangle()
                .fill(color.opacity(0.08))

            // Left accent bar
            Rectangle()
                .fill(color.opacity(0.5))
                .frame(width: 3)

            // Text
            VStack(alignment: .leading, spacing: 1) {
                Text(event.title)
                    .font(.system(size: 10 * textScale))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
                if event.duration > 30 {
                    Text(timeRange)
                        .font(.system(size: 9 * textScale))
                        .foregroundStyle(Theme.textTertiary.opacity(0.7))
                }
            }
            .padding(.leading, 8)
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
