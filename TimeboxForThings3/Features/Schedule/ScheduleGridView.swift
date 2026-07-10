import SwiftUI

/// RHS panel: vertical time grid with scheduled blocks.
struct ScheduleGridView: View {
    @Environment(AppState.self) private var appState

    private let topPadding: CGFloat = 12
    private let bottomPadding: CGFloat = 20

    var body: some View {
        VStack(spacing: 0) {
            SummaryBarView()
            Divider()

            // Time grid — fills all available vertical space
            GeometryReader { geo in
                ScrollViewReader { proxy in
                    ScrollView(.vertical) {
                        ZStack(alignment: .topLeading) {
                            // Background grid lines
                            gridLines

                            // Calendar events (behind everything, like shaded time slots)
                            calendarLayer
                                .padding(.top, topPadding)

                            // Drop zone (invisible, handles drops and double-clicks)
                            dropZone
                                .padding(.top, topPadding)

                            // Scheduled blocks (on top of calendar events)
                            blocksLayer
                                .padding(.top, topPadding)

                            // Now line
                            if appState.showCurrentTimeLine {
                                NowLineView(startHour: appState.startHour, endHour: appState.endHour)
                                    .padding(.top, topPadding)
                                    .id("nowLine")
                            }
                        }
                        .frame(width: geo.size.width, height: max(gridHeight + topPadding + bottomPadding, geo.size.height))
                    }
                    .onAppear {
                        proxy.scrollTo("nowLine", anchor: .center)
                    }
                }
            }
        }
        .background(Theme.contentBackground)
    }

    // MARK: - Layout calculations

    private var startMinutes: Int { appState.startHour * 60 }

    private var totalSlots: Int {
        (appState.endHour - appState.startHour) * 2
    }

    private var gridHeight: CGFloat {
        CGFloat(totalSlots) * Theme.slotHeight
    }

    private func yPosition(for minutesSinceMidnight: Int) -> CGFloat {
        CGFloat(minutesSinceMidnight - startMinutes) * Theme.pointsPerMinute
    }

    private func height(for duration: Int) -> CGFloat {
        CGFloat(duration) * Theme.pointsPerMinute
    }

    // MARK: - Drop zone

    private var dropZone: some View {
        DropTargetGrid(
            startMinutes: startMinutes,
            pointsPerMinute: Theme.pointsPerMinute,
            slotHeight: height(for: 30),
            timeLabelWidth: Theme.timeLabelWidth,
            onDrop: { taskUUID, minutes in
                guard let store = appState.scheduleStore else { return }
                let placed = clamp(start: snapToGrid(minutes), duration: 30)
                _ = try? store.addTimeBlock(
                    taskUUID: taskUUID,
                    date: appState.selectedDate,
                    startTime: placed.start,
                    duration: placed.duration
                )
            },
            onDoubleClick: { minutes in
                guard let store = appState.scheduleStore else { return }
                let placed = clamp(start: snapToGrid(minutes), duration: 30)
                _ = try? store.addStandaloneBlock(
                    date: appState.selectedDate,
                    startTime: placed.start,
                    duration: placed.duration
                )
            },
            onSingleClick: {
                appState.selectedBlockID = nil
            }
        )
    }

    private func minutesFromLocation(_ location: CGPoint) -> Int {
        let yOffset = location.y
        return startMinutes + Int(yOffset / Theme.pointsPerMinute)
    }

    private func snapToGrid(_ minutes: Int, gridSize: Int = 15) -> Int {
        (minutes / gridSize) * gridSize
    }

    /// Clamp a block's start time to the visible schedule bounds.
    private func clampStart(_ start: Int, duration: Int) -> Int {
        let minMinutes = appState.startHour * 60
        let maxMinutes = appState.endHour * 60
        return max(minMinutes, min(start, maxMinutes - duration))
    }

    /// Clamp both start and duration so the block stays fully inside the visible day.
    private func clamp(start: Int, duration: Int) -> (start: Int, duration: Int) {
        let minMinutes = appState.startHour * 60
        let maxMinutes = appState.endHour * 60
        let clampedDuration = max(15, min(duration, maxMinutes - minMinutes))
        let clampedStart = max(minMinutes, min(start, maxMinutes - clampedDuration))
        return (clampedStart, clampedDuration)
    }

    // MARK: - Calendar events layer

    private var calendarLayer: some View {
        ZStack(alignment: .topLeading) {
            ForEach(visibleCalendarEvents) { positioned in
                CalendarEventView(
                    event: positioned.clamped,
                    labelStartMinutes: positioned.trueStart,
                    labelDurationMinutes: positioned.trueDuration
                )
                .offset(
                    x: Theme.timeLabelWidth + 4,
                    y: yPosition(for: positioned.clamped.startMinutes)
                )
                .padding(.trailing, Theme.timeLabelWidth + 12)
            }
        }
    }

    /// A calendar event positioned for the grid: `clamped` carries the geometry
    /// (offset/height) restricted to the visible window, while `trueStart`/
    /// `trueDuration` preserve the real event times for the label.
    private struct PositionedEvent: Identifiable {
        let id: String
        let clamped: CalendarEvent
        let trueStart: Int
        let trueDuration: Int
    }

    /// Timed calendar events clamped to the visible [startHour, endHour] window.
    /// Events entirely outside the window are dropped; events crossing a boundary
    /// are clipped (geometry only) so they never render above or below the grid,
    /// while the label still shows the event's true start/end times.
    private var visibleCalendarEvents: [PositionedEvent] {
        let endMinutes = appState.endHour * 60
        return appState.calendarProvider.events.compactMap { event in
            guard !event.isAllDay else { return nil }
            let eventStart = event.startMinutes
            let eventEnd = event.startMinutes + event.duration
            let visibleStart = max(eventStart, startMinutes)
            let visibleEnd = min(eventEnd, endMinutes)
            guard visibleEnd > visibleStart else { return nil }
            let clamped: CalendarEvent
            if visibleStart == eventStart && visibleEnd == eventEnd {
                clamped = event
            } else {
                clamped = CalendarEvent(
                    id: event.id,
                    title: event.title,
                    startMinutes: visibleStart,
                    duration: visibleEnd - visibleStart,
                    calendarColor: event.calendarColor,
                    isAllDay: false
                )
            }
            return PositionedEvent(
                id: event.id,
                clamped: clamped,
                trueStart: eventStart,
                trueDuration: event.duration
            )
        }
    }

    // MARK: - Blocks layer

    private var blocksLayer: some View {
        let tasksByID = Dictionary(uniqueKeysWithValues: appState.taskProvider.tasks.map { ($0.id, $0) })

        return ZStack(alignment: .topLeading) {
            if let store = appState.scheduleStore {
                ForEach(store.timeBlocks) { block in
                    let task = tasksByID[block.taskUUID]
                    TaskBlockView(
                        block: block,
                        taskItem: task,
                        onDelete: {
                            try? store.deleteTimeBlock(id: block.id)
                        },
                        onMove: { newStart in
                            var updated = block
                            updated.startTime = self.clampStart(newStart, duration: block.duration)
                            try? store.updateTimeBlock(updated)
                        },
                        onResize: { newStart, newDuration in
                            var updated = block
                            (updated.startTime, updated.duration) = self.clamp(start: newStart, duration: newDuration)
                            try? store.updateTimeBlock(updated)
                        },
                        onColorCycle: {
                            var updated = block
                            let current = block.colorIndex ?? 0
                            updated.colorIndex = (current + 1) % ProjectColorGenerator.blockPalette.count
                            try? store.updateTimeBlock(updated)
                        }
                    )
                    .offset(
                        x: Theme.timeLabelWidth + 4,
                        y: yPosition(for: block.startTime)
                    )
                    .padding(.trailing, Theme.timeLabelWidth + 12)
                }

                ForEach(store.standaloneBlocks) { block in
                    StandaloneBlockView(
                        block: block,
                        onDelete: {
                            try? store.deleteStandaloneBlock(id: block.id)
                        },
                        onTitleChange: { newTitle in
                            var updated = block
                            updated.title = newTitle
                            try? store.updateStandaloneBlock(updated)
                        },
                        onColorCycle: {
                            var updated = block
                            updated.colorIndex = (block.colorIndex + 1) % ProjectColorGenerator.blockPalette.count
                            try? store.updateStandaloneBlock(updated)
                        },
                        onMove: { newStart in
                            var updated = block
                            updated.startTime = self.clampStart(newStart, duration: block.duration)
                            try? store.updateStandaloneBlock(updated)
                        },
                        onResize: { newStart, newDuration in
                            var updated = block
                            (updated.startTime, updated.duration) = self.clamp(start: newStart, duration: newDuration)
                            try? store.updateStandaloneBlock(updated)
                        }
                    )
                    .offset(
                        x: Theme.timeLabelWidth + 4,
                        y: yPosition(for: block.startTime)
                    )
                    .padding(.trailing, Theme.timeLabelWidth + 12)
                }

            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Grid lines

    private var gridLines: some View {
        Canvas { context, size in
            let endMinutes = appState.endHour * 60

            for minutes in stride(from: startMinutes, through: endMinutes, by: 30) {
                let y = topPadding + CGFloat(minutes - startMinutes) * Theme.pointsPerMinute
                let isHour = minutes % 60 == 0

                // Grid line — solid for hours, dashed for half-hours
                var path = Path()
                path.move(to: CGPoint(x: Theme.timeLabelWidth, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))

                if isHour {
                    context.stroke(
                        path,
                        with: .color(Theme.gridLineColor.opacity(0.5)),
                        lineWidth: 1
                    )
                } else {
                    context.stroke(
                        path,
                        with: .color(Theme.gridLineColor.opacity(0.25)),
                        style: StrokeStyle(lineWidth: 0.5, dash: [4, 4])
                    )
                }

                // Time label at every hour mark (including the last one)
                if isHour {
                    let hour = minutes / 60
                    let label: String
                    if hour == 0 { label = "12 AM" }
                    else if hour < 12 { label = "\(hour) AM" }
                    else if hour == 12 { label = "12 PM" }
                    else { label = "\(hour - 12) PM" }

                    let text = Text(label)
                        .font(Theme.metadata)
                        .foregroundStyle(Theme.textSecondary)
                    context.draw(
                        context.resolve(text),
                        at: CGPoint(x: Theme.timeLabelWidth - 8, y: y),
                        anchor: .trailing
                    )
                }
            }
        }
    }
}
