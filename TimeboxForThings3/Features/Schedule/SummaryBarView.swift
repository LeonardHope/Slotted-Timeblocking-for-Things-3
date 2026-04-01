import SwiftUI

/// Top bar showing scheduled task count, planned hours, free hours, and settings gear.
struct SummaryBarView: View {
    @Environment(AppState.self) private var appState
    @State private var showingSettings = false

    var body: some View {
        HStack(spacing: 16) {
            // Date
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.todayGold)
                Text(dateString)
                    .font(Theme.pageTitle)
            }

            Spacer()

            let stats = computeStats()

            // Scheduled count
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 12))
                Text("\(stats.taskCount) tasks")
                    .font(Theme.metadataSemibold)
            }
            .foregroundStyle(Theme.textSecondary)

            // Planned hours
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 12))
                Text(String(format: "%.1fh planned", stats.plannedHours))
                    .font(Theme.metadataSemibold)
            }
            .foregroundStyle(Theme.textSecondary)

            // Free hours
            HStack(spacing: 4) {
                Image(systemName: "clock.badge.checkmark")
                    .font(.system(size: 12))
                Text(String(format: "%.1fh free", stats.freeHours))
                    .font(Theme.metadataSemibold)
            }
            .foregroundStyle(stats.freeHours < 0 ? Theme.overdueRed : Theme.textSecondary)

            // Settings gear
            Button {
                showingSettings.toggle()
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textSecondary)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showingSettings, arrowEdge: .bottom) {
                SettingsView()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: appState.selectedDate)
    }

    private func computeStats() -> (taskCount: Int, plannedHours: Double, freeHours: Double) {
        guard let store = appState.scheduleStore else {
            return (0, 0, Double(appState.endHour - appState.startHour))
        }

        let taskCount = store.timeBlocks.count
        let totalMinutes = store.timeBlocks.map(\.duration).reduce(0, +)
            + store.standaloneBlocks.map(\.duration).reduce(0, +)
        let plannedHours = Double(totalMinutes) / 60.0
        let workHours = Double(appState.endHour - appState.startHour)
        let freeHours = workHours - plannedHours

        return (taskCount, plannedHours, freeHours)
    }
}
