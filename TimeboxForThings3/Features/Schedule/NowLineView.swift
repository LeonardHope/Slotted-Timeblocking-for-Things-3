import SwiftUI

/// Red horizontal line showing the current time on the schedule grid.
struct NowLineView: View {
    let startHour: Int
    @State private var now = Date()

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        let position = yPositionForNow
        if let position {
            HStack(spacing: 4) {
                Text(timeString)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.nowLineRed)
                    .frame(width: Theme.timeLabelWidth - 8, alignment: .trailing)

                Rectangle()
                    .fill(Theme.nowLineRed)
                    .frame(height: 1.5)
            }
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

        guard currentMinutes >= startMinutes else { return nil }
        return CGFloat(currentMinutes - startMinutes) * Theme.pointsPerMinute
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: now)
    }
}
