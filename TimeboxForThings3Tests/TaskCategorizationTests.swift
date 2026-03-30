import Foundation
import Testing
@testable import TimeboxForThings3

@Suite("Task Categorization")
struct TaskCategorizationTests {

    private func makeTask(
        startValue: Int = 1,
        startDate: Date? = nil,
        deadline: Date? = nil,
        todayIndex: Int = -1
    ) -> TaskItem {
        TaskItem(
            id: UUID().uuidString,
            title: "Test Task",
            notes: nil,
            projectName: nil,
            projectUUID: nil,
            areaName: nil,
            headingName: nil,
            tags: [],
            startDate: startDate,
            deadline: deadline,
            creationDate: .now,
            todayIndex: todayIndex,
            startValue: startValue,
            checklistTotal: 0,
            checklistOpen: 0
        )
    }

    @Test("Inbox tasks categorized as inbox")
    func inboxTask() {
        let task = makeTask(startValue: 0)
        #expect(TaskCategorizer.categorize(task) == .inbox)
    }

    @Test("Someday tasks categorized as someday")
    func somedayTask() {
        let task = makeTask(startValue: 2)
        #expect(TaskCategorizer.categorize(task) == .someday)
    }

    @Test("Overdue task with past deadline")
    func overdueTask() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        let task = makeTask(deadline: yesterday)
        #expect(TaskCategorizer.categorize(task) == .overdue)
    }

    @Test("Task with today's start date")
    func todayTask() {
        let today = Calendar.current.startOfDay(for: .now)
        let task = makeTask(startDate: today)
        #expect(TaskCategorizer.categorize(task) == .today)
    }

    @Test("Task with future start date is upcoming")
    func upcomingTask() {
        let nextWeek = Calendar.current.date(byAdding: .day, value: 5, to: .now)!
        let task = makeTask(startDate: nextWeek)
        #expect(TaskCategorizer.categorize(task) == .upcoming)
    }

    @Test("Anytime task with positive todayIndex categorized as today")
    func todayIndexTask() {
        let task = makeTask(todayIndex: 0)
        #expect(TaskCategorizer.categorize(task) == .today)
    }

    @Test("Anytime task with no date and negative todayIndex categorized as anytime")
    func anytimeTask() {
        let task = makeTask(todayIndex: -1)
        #expect(TaskCategorizer.categorize(task) == .anytime)
    }
}
