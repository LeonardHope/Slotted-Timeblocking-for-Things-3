# Code Review Findings

## 1. Critical: Midnight rollover can delete the wrong records and desynchronize the UI

- `ScheduleStore.clearBlocks(for:)` deletes rows for the passed date in SQLite, but it derives deleted IDs from the currently loaded in-memory arrays and then clears those arrays wholesale.
- `AppState.observeDayChange()` always calls `clearBlocks(for: yesterday)` at midnight.
- If the user is viewing any date other than yesterday when midnight passes, the app can blank the visible schedule and emit CloudKit deletions for the wrong set of blocks.

References:
- [TimeboxForThings3/Data/Schedule/ScheduleStore.swift](/Users/leonard/Projects/Timebox%20for%20Things%203/TimeboxForThings3/Data/Schedule/ScheduleStore.swift#L154)
- [TimeboxForThings3/App/AppState.swift](/Users/leonard/Projects/Timebox%20for%20Things%203/TimeboxForThings3/App/AppState.swift#L99)

## 2. High: Blocks can be persisted outside the visible work window and become unreachable

- Keyboard nudging clamps only to `0`, not to the configured day bounds.
- Drag move and resize logic also enforce only a lower bound.
- The grid rendering is bounded by `startHour` and `endHour`, so blocks saved beyond that range can end up clipped off-screen while still remaining persisted.

References:
- [TimeboxForThings3/App/ContentView.swift](/Users/leonard/Projects/Timebox%20for%20Things%203/TimeboxForThings3/App/ContentView.swift#L28)
- [TimeboxForThings3/Features/Schedule/TaskBlockView.swift](/Users/leonard/Projects/Timebox%20for%20Things%203/TimeboxForThings3/Features/Schedule/TaskBlockView.swift#L137)
- [TimeboxForThings3/Features/Schedule/StandaloneBlockView.swift](/Users/leonard/Projects/Timebox%20for%20Things%203/TimeboxForThings3/Features/Schedule/StandaloneBlockView.swift#L131)
- [TimeboxForThings3/Features/Schedule/ScheduleGridView.swift](/Users/leonard/Projects/Timebox%20for%20Things%203/TimeboxForThings3/Features/Schedule/ScheduleGridView.swift#L55)

## 3. High: CloudKit conflict handling only protects the currently loaded date

- Remote change reconciliation compares incoming records only against `store.timeBlocks` / `store.standaloneBlocks`.
- Those arrays contain records only for `currentDateString`.
- A newer local edit on any other date can therefore be overwritten by a remote change instead of being detected and re-pushed.

References:
- [TimeboxForThings3/Data/Schedule/ScheduleSyncEngine.swift](/Users/leonard/Projects/Timebox%20for%20Things%203/TimeboxForThings3/Data/Schedule/ScheduleSyncEngine.swift#L218)
- [TimeboxForThings3/Data/Schedule/ScheduleStore.swift](/Users/leonard/Projects/Timebox%20for%20Things%203/TimeboxForThings3/Data/Schedule/ScheduleStore.swift#L37)

## 4. Medium: In-memory block ordering is stale after moves and resizes

- `updateTimeBlock(_:)` and `updateStandaloneBlock(_:)` replace the updated element in place.
- They do not re-sort the arrays after `startTime` changes, even though add/load/upsert paths do sort.
- This can leave rendering order inconsistent until the next reload.

References:
- [TimeboxForThings3/Data/Schedule/ScheduleStore.swift](/Users/leonard/Projects/Timebox%20for%20Things%203/TimeboxForThings3/Data/Schedule/ScheduleStore.swift#L78)
- [TimeboxForThings3/Data/Schedule/ScheduleStore.swift](/Users/leonard/Projects/Timebox%20for%20Things%203/TimeboxForThings3/Data/Schedule/ScheduleStore.swift#L131)

## Testing note

- Current test coverage is limited to task categorization and the Things date decoder.
- There is no coverage around `ScheduleStore`, midnight rollover, or CloudKit reconciliation.
- `xcodebuild test -scheme TimeboxForThings3 -destination 'platform=macOS'` could not be completed in this environment because package resolution failed under sandbox restrictions with `sandbox-exec: sandbox_apply: Operation not permitted`.
