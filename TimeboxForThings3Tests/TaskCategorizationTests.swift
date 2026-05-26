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

    @Test("Someday task with no startDate goes to someday")
    func somedayTask() {
        let task = makeTask(startValue: 2)
        #expect(TaskCategorizer.categorize(task) == .someday)
    }

    @Test("Someday task with future startDate goes to upcoming")
    func somedayWithFutureDate() {
        let nextWeek = Calendar.current.date(byAdding: .day, value: 5, to: .now)!
        let task = makeTask(startValue: 2, startDate: nextWeek)
        #expect(TaskCategorizer.categorize(task) == .upcoming)
    }

    @Test("Task with start date today goes to today")
    func todayStartDate() {
        let today = Calendar.current.startOfDay(for: .now)
        let task = makeTask(startDate: today)
        #expect(TaskCategorizer.categorize(task) == .today)
    }

    @Test("Task with past start date goes to today")
    func pastStartDate() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        let task = makeTask(startDate: yesterday)
        #expect(TaskCategorizer.categorize(task) == .today)
    }

    @Test("Task with deadline today and no start date goes to today")
    func deadlineToday() {
        let today = Calendar.current.startOfDay(for: .now)
        let task = makeTask(deadline: today)
        #expect(TaskCategorizer.categorize(task) == .today)
    }

    @Test("Task with past deadline and no start date goes to today")
    func pastDeadline() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        let task = makeTask(deadline: yesterday)
        #expect(TaskCategorizer.categorize(task) == .today)
    }

    @Test("Task with future start date goes to upcoming")
    func upcomingTask() {
        let nextWeek = Calendar.current.date(byAdding: .day, value: 5, to: .now)!
        let task = makeTask(startDate: nextWeek)
        #expect(TaskCategorizer.categorize(task) == .upcoming)
    }

    @Test("Active task with no dates goes to anytime")
    func anytimeTask() {
        let task = makeTask()
        #expect(TaskCategorizer.categorize(task) == .anytime)
    }

    @Test("Active task with future deadline only goes to anytime")
    func futureDeadlineOnly() {
        let nextMonth = Calendar.current.date(byAdding: .day, value: 30, to: .now)!
        let task = makeTask(deadline: nextMonth)
        #expect(TaskCategorizer.categorize(task) == .anytime)
    }
}
