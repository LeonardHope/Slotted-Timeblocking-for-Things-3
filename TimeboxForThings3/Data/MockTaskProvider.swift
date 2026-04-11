import Foundation
import Observation

/// Provides curated demo task data for screenshots and previews.
/// Activated by setting `SLOTTED_DEMO=1` in the Xcode scheme environment variables.
@Observable
@MainActor
final class MockTaskProvider: TaskProvider {
    var tasks: [TaskItem] = []
    var projects: [ProjectInfo] = []
    var tags: [TagInfo] = []
    var isLoading: Bool = false
    var error: Error? = nil

    static var isEnabled: Bool {
        ProcessInfo.processInfo.environment["SLOTTED_DEMO"] == "1"
    }

    func startObserving() async {
        loadDemoData()
    }

    func stopObserving() {}
    func refresh() async {}

    private func loadDemoData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let thisWeek = calendar.date(byAdding: .day, value: 3, to: today)!
        let nextWeek = calendar.date(byAdding: .day, value: 8, to: today)!
        let nextMonth = calendar.date(byAdding: .day, value: 25, to: today)!

        // Project UUIDs
        let acmeUUID = "proj-acme-redesign"
        let northwindUUID = "proj-northwind-api"
        let q2PlanningUUID = "proj-q2-planning"
        let homeUUID = "proj-home-renovation"
        let financialUUID = "proj-financial"

        projects = [
            ProjectInfo(id: acmeUUID, title: "Acme Website Redesign", areaName: "Work"),
            ProjectInfo(id: northwindUUID, title: "Northwind API Integration", areaName: "Work"),
            ProjectInfo(id: q2PlanningUUID, title: "Q2 Planning", areaName: "Work"),
            ProjectInfo(id: homeUUID, title: "Home Renovation", areaName: "Personal"),
            ProjectInfo(id: financialUUID, title: "Financial", areaName: "Personal"),
        ]

        tasks = [
            // === TODAY ===
            mock("Review homepage mockups from designer",
                 project: "Acme Website Redesign", projectID: acmeUUID, area: "Work",
                 startDate: today),
            mock("Implement OAuth flow for Northwind",
                 project: "Northwind API Integration", projectID: northwindUUID, area: "Work",
                 startDate: today, deadline: tomorrow),
            mock("Send Q2 budget proposal to leadership",
                 project: "Q2 Planning", projectID: q2PlanningUUID, area: "Work",
                 startDate: today, deadline: today),
            mock("Call plumber about kitchen sink",
                 project: "Home Renovation", projectID: homeUUID, area: "Personal",
                 startDate: today),
            mock("Pay credit card bill",
                 project: "Financial", projectID: financialUUID, area: "Personal",
                 startDate: today, deadline: tomorrow),

            // === UPCOMING ===
            mock("Prepare client presentation deck",
                 project: "Acme Website Redesign", projectID: acmeUUID, area: "Work",
                 startDate: thisWeek),
            mock("Code review for API team",
                 project: "Northwind API Integration", projectID: northwindUUID, area: "Work",
                 startDate: thisWeek),
            mock("Schedule Q2 kickoff meeting",
                 project: "Q2 Planning", projectID: q2PlanningUUID, area: "Work",
                 startDate: nextWeek),
            mock("Get quotes from 3 contractors",
                 project: "Home Renovation", projectID: homeUUID, area: "Personal",
                 startDate: thisWeek, deadline: nextWeek),
            mock("File 2025 tax return",
                 project: "Financial", projectID: financialUUID, area: "Personal",
                 startDate: nextMonth, deadline: nextMonth),

            // === ANYTIME (no startDate, start=1) ===
            mock("Refactor checkout component",
                 project: "Acme Website Redesign", projectID: acmeUUID, area: "Work",
                 startValue: 1),
            mock("Write API documentation",
                 project: "Northwind API Integration", projectID: northwindUUID, area: "Work",
                 startValue: 1),
            mock("Research competitive analysis tools",
                 project: "Q2 Planning", projectID: q2PlanningUUID, area: "Work",
                 startValue: 1),
            mock("Pick paint colors for living room",
                 project: "Home Renovation", projectID: homeUUID, area: "Personal",
                 startValue: 1),
            mock("Set up automatic savings transfer",
                 project: "Financial", projectID: financialUUID, area: "Personal",
                 startValue: 1),

            // === INBOX ===
            mock("Look into that productivity book Sarah mentioned", startValue: 1),
            mock("Reply to vendor email about quarterly invoice", startValue: 1),

            // === SOMEDAY ===
            mock("Learn SwiftUI animations",
                 project: nil, area: "Work",
                 startValue: 2),
            mock("Plan summer vacation to Italy",
                 project: nil, area: "Personal",
                 startValue: 2),
        ]
    }

    private func mock(
        _ title: String,
        project: String? = nil,
        projectID: String? = nil,
        area: String? = nil,
        startDate: Date? = nil,
        deadline: Date? = nil,
        startValue: Int = 1
    ) -> TaskItem {
        TaskItem(
            id: UUID().uuidString,
            title: title,
            notes: nil,
            projectName: project,
            projectUUID: projectID,
            areaName: area,
            headingName: nil,
            tags: [],
            startDate: startDate,
            deadline: deadline,
            creationDate: .now,
            todayIndex: -1,
            startValue: startValue,
            checklistTotal: 0,
            checklistOpen: 0
        )
    }
}
