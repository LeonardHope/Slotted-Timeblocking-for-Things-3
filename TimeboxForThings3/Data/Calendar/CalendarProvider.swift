import EventKit
import Foundation
import Observation

/// A calendar event to display on the schedule grid.
struct CalendarEvent: Identifiable, Hashable {
    let id: String
    let title: String
    let startMinutes: Int  // minutes from midnight
    let duration: Int      // minutes
    let calendarColor: CGColor
    let isAllDay: Bool
}

/// Reads calendar events via EventKit.
@Observable
@MainActor
final class CalendarProvider {
    private let store = EKEventStore()
    var events: [CalendarEvent] = []
    private(set) var accessGranted = false

    func requestAccess() async {
        do {
            let granted = try await store.requestFullAccessToEvents()
            accessGranted = granted
            if granted {
                observeChanges()
            }
        } catch {
            accessGranted = false
        }
    }

    func fetchEvents(for date: Date) {
        guard accessGranted else { return }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }

        let predicate = store.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        let ekEvents = store.events(matching: predicate)

        events = ekEvents.compactMap { event in
            guard !event.isAllDay else {
                return CalendarEvent(
                    id: event.eventIdentifier,
                    title: event.title ?? "Untitled",
                    startMinutes: 0,
                    duration: 0,
                    calendarColor: event.calendar.cgColor,
                    isAllDay: true
                )
            }

            let startMinutes = calendar.component(.hour, from: event.startDate) * 60
                + calendar.component(.minute, from: event.startDate)
            let endMinutes = calendar.component(.hour, from: event.endDate) * 60
                + calendar.component(.minute, from: event.endDate)
            let duration = max(15, endMinutes - startMinutes)

            return CalendarEvent(
                id: event.eventIdentifier,
                title: event.title ?? "Untitled",
                startMinutes: startMinutes,
                duration: duration,
                calendarColor: event.calendar.cgColor,
                isAllDay: false
            )
        }
    }

    private func observeChanges() {
        // EKEventStoreChanged is observed by AppState to trigger re-fetch
    }

    /// Whether the user has calendar events enabled and access granted.
    var isAvailable: Bool { accessGranted }
}
