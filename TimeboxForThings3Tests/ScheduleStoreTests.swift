import CloudKit
import Foundation
import Testing
@testable import TimeboxForThings3

@MainActor
struct ScheduleStoreTests {
    private func makeStore() throws -> ScheduleStore {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ScheduleStoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return try ScheduleStore(path: dir.appendingPathComponent("schedule.sqlite").path)
    }

    private func date(_ iso: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: iso)!
    }

    // MARK: - clearBlocks(for:)

    @Test func clearForDateOnlyAffectsThatDate() throws {
        let store = try makeStore()
        try store.addTimeBlock(taskUUID: "task-a", date: date("2026-07-08"), startTime: 540)
        try store.addTimeBlock(taskUUID: "task-b", date: date("2026-07-09"), startTime: 600)

        try store.clearBlocks(for: date("2026-07-08"))

        #expect(try store.allTimeBlocks().map(\.taskUUID) == ["task-b"])
    }

    @Test func clearForDateLeavesInMemoryBlocksOfOtherDates() async throws {
        let store = try makeStore()
        try store.addTimeBlock(taskUUID: "task-a", date: date("2026-07-08"), startTime: 540)
        try store.addTimeBlock(taskUUID: "task-b", date: date("2026-07-09"), startTime: 600)
        try await store.loadBlocks(for: date("2026-07-09"))

        try store.clearBlocks(for: date("2026-07-08"))

        #expect(store.timeBlocks.map(\.taskUUID) == ["task-b"])
    }

    @Test func clearForDateEmitsDeletionsOnlyForThatDate() throws {
        let store = try makeStore()
        let cleared = try store.addTimeBlock(taskUUID: "task-a", date: date("2026-07-08"), startTime: 540)
        try store.addStandaloneBlock(title: "Lunch", date: date("2026-07-09"), startTime: 720)

        var deletedIDs: [String] = []
        store.onSyncChange = { change in
            if case .deleted(let recordID, _) = change {
                deletedIDs.append(recordID.recordName)
            }
        }
        try store.clearBlocks(for: date("2026-07-08"))

        #expect(deletedIDs == [cleared.id])
    }

    // MARK: - clearBlocks(before:)

    @Test func clearBeforeRemovesAllEarlierDatesOnly() throws {
        let store = try makeStore()
        try store.addTimeBlock(taskUUID: "old-1", date: date("2026-07-01"), startTime: 540)
        try store.addStandaloneBlock(title: "old-2", date: date("2026-07-05"), startTime: 600)
        try store.addTimeBlock(taskUUID: "today", date: date("2026-07-09"), startTime: 660)

        try store.clearBlocks(before: date("2026-07-09"))

        #expect(try store.allTimeBlocks().map(\.taskUUID) == ["today"])
        #expect(try store.allStandaloneBlocks().isEmpty)
    }

    @Test func clearBeforeKeepsInMemoryBlocksWhenViewingToday() async throws {
        let store = try makeStore()
        try store.addTimeBlock(taskUUID: "old", date: date("2026-07-08"), startTime: 540)
        try store.addTimeBlock(taskUUID: "today", date: date("2026-07-09"), startTime: 600)
        try await store.loadBlocks(for: date("2026-07-09"))

        try store.clearBlocks(before: date("2026-07-09"))

        #expect(store.timeBlocks.map(\.taskUUID) == ["today"])
    }

    // MARK: - carryForwardStandaloneBlocks(to:)

    @Test func carryForwardCopiesRoutinesFromMostRecentDay() throws {
        let store = try makeStore()
        try store.addStandaloneBlock(title: "Stale", date: date("2026-07-01"), startTime: 480)
        try store.addStandaloneBlock(title: "Lunch", date: date("2026-07-06"), startTime: 720, duration: 60)
        try store.addTimeBlock(taskUUID: "task-a", date: date("2026-07-06"), startTime: 540)

        // Several days passed with the app closed; today is the 9th
        try store.carryForwardStandaloneBlocks(to: date("2026-07-09"))

        let todayString = "2026-07-09"
        let timeBlocks = try store.allTimeBlocks().filter { $0.date == todayString }
        let standaloneBlocks = try store.allStandaloneBlocks().filter { $0.date == todayString }
        // Task-linked blocks are deliberately not carried forward — only routines
        #expect(timeBlocks.isEmpty)
        #expect(standaloneBlocks.map(\.title) == ["Lunch"])
        // Source day is left untouched
        #expect(try store.allStandaloneBlocks().filter { $0.date == "2026-07-06" }.count == 1)
    }

    @Test func carryForwardSkipsWhenTargetAlreadyHasBlocks() throws {
        let store = try makeStore()
        try store.addStandaloneBlock(title: "Yesterday", date: date("2026-07-08"), startTime: 540)
        try store.addStandaloneBlock(title: "Planned ahead", date: date("2026-07-09"), startTime: 600)

        try store.carryForwardStandaloneBlocks(to: date("2026-07-09"))

        let todayBlocks = try store.allStandaloneBlocks().filter { $0.date == "2026-07-09" }
        #expect(todayBlocks.map(\.title) == ["Planned ahead"])
    }

    @Test func carryForwardDoesNothingWithNoEarlierBlocks() throws {
        let store = try makeStore()
        try store.carryForwardStandaloneBlocks(to: date("2026-07-09"))
        #expect(try store.allTimeBlocks().isEmpty)
        #expect(try store.allStandaloneBlocks().isEmpty)
    }

    @Test func carryForwardCopiesGetFreshIDs() throws {
        let store = try makeStore()
        let original = try store.addStandaloneBlock(title: "Lunch", date: date("2026-07-08"), startTime: 720)

        try store.carryForwardStandaloneBlocks(to: date("2026-07-09"))

        let copied = try #require(store.allStandaloneBlocks().first { $0.date == "2026-07-09" })
        #expect(copied.id != original.id)
        #expect(copied.title == original.title)
        #expect(copied.startTime == original.startTime)
    }

    // MARK: - Ordering

    @Test func updateTimeBlockKeepsArraySorted() async throws {
        let store = try makeStore()
        let first = try store.addTimeBlock(taskUUID: "first", date: date("2026-07-09"), startTime: 540)
        try store.addTimeBlock(taskUUID: "second", date: date("2026-07-09"), startTime: 600)
        try await store.loadBlocks(for: date("2026-07-09"))

        var moved = first
        moved.startTime = 660
        try store.updateTimeBlock(moved)

        #expect(store.timeBlocks.map(\.taskUUID) == ["second", "first"])
    }
}
