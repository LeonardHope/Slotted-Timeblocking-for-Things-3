import SwiftUI

/// Red horizontal line showing the current time on the schedule grid.
struct NowLineView: View {
    let startHour: Int
    let endHour: Int
    @State private var now = Date()

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        let position = yPositionForNow
        if let position {
            // Small red dot on the left edge + line across the grid
            HStack(spacing: 0) {
                Spacer()
                    .frame(width: Theme.timeLabelWidth - 4)

                Circle()
                    .fill(Theme.nowLineRed)
                    .frame(width: 8, height: 8)

                Rectangle()
                    .fill(Theme.nowLineRed)
                    .frame(height: 1.5)
            }
            .frame(height: 0)
            .offset(y: position)
            .onReceive(timer) { _ in
                now = Date()
            }
        }
    }

    private var yPositionForNow: CGFloat? {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let currentMinutes = hour * 60 + minute
        let startMinutes = startHour * 60
        let endMinutes = endHour * 60

        guard currentMinutes >= startMinutes, currentMinutes <= endMinutes else { return nil }
        return CGFloat(currentMinutes - startMinutes) * Theme.pointsPerMinute
    }
}
