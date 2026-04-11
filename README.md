# Slotted

**A native macOS time blocking companion for [Things 3](https://culturedcode.com/things/).**

Things 3 is great for managing tasks but lacks a way to plan your day on a timeline. Slotted reads your Things 3 tasks and lets you drag them onto a visual schedule grid — turning your task list into a real day plan.

![Slotted screenshot](docs/screenshot.png)

## Why Slotted

Time blocking turns intentions into commitments. Instead of a flat list of "things I might do today," you decide *when* you'll do each one and *how long* it will take. Slotted brings that practice to Things 3 without changing how you already use it.

- **Read-only**: Slotted never modifies your Things 3 data
- **Live updates**: changes in Things 3 appear instantly via file system monitoring
- **Native**: built with SwiftUI for macOS, not a web wrapper
- **Private**: your data stays on your devices (with optional iCloud sync between your own Macs)

## Features

### Task List (left panel)

- Live read-only access to your Things 3 database
- Tasks grouped by Things 3 categories: Inbox, Today, Upcoming, Anytime, Someday
- Area → Project hierarchy with expand/collapse controls
- Sorted by start date, then deadline, then alphabetically
- Deadline indicators with red calendar icon
- Completed tasks automatically removed from the schedule
- Option to hide or keep tasks visible after scheduling

### Schedule Grid (right panel)

- **Drag tasks** from the list onto the timeline
- **Single-gesture interaction**: drag from the top edge to resize the start, the bottom edge to resize the end, or the middle to move the block
- **Smooth drag** with snap-to-grid on release (15-minute increments)
- **Standalone time blocks** for things that aren't tasks: double-click an empty slot to create a block for "Lunch", "Morning run", etc.
- **Custom block colors**: click the color dot on hover to cycle through 10 colors
- **Multi-timebox**: schedule the same task in multiple time slots (e.g., before and after lunch)
- **Keyboard shortcuts**: arrow keys nudge selected blocks by 15 minutes, Delete removes them
- **Drop target highlight** when dragging from the task list
- **Now line** showing the current time
- **Carry forward**: blocks can persist into the next day, so recurring routines (lunch, breaks) don't need to be recreated

### Calendar Integration

- Import events from macOS calendars and display them on the schedule
- Calendar events use a distinct hatched pattern so they're easy to distinguish from task blocks
- Read-only — calendar events block out time but can't be moved or resized
- Auto-refreshes when calendar changes
- Toggle on/off in Settings

### Settings

- Schedule hours (start/end)
- Text size slider
- Light / Dark / Auto appearance
- Hide empty categories
- Hide empty projects
- Hide scheduled tasks (toggle off for multi-timebox)
- Show / hide deadlines
- Show / hide current time line
- Show calendar events
- Clear schedule at midnight (when off, blocks carry forward to the next day)
- iCloud Sync on/off

### iCloud Sync

- Sync schedule data across your devices via CloudKit
- Uses CKSyncEngine for reliable, offline-capable sync with conflict resolution
- Persisted server record cache for clean restarts
- Simple toggle — no account setup needed beyond being signed into iCloud

## Your Things 3 Data is Safe

Slotted uses **read-only access** to your Things 3 database. It cannot modify, delete, or corrupt your data.

- The database connection is opened with SQLite's `SQLITE_OPEN_READONLY` flag — write attempts are rejected at the database engine level
- There are no write statements (INSERT, UPDATE, DELETE) against the Things 3 database anywhere in the codebase
- Your schedule is stored in a completely separate database
- File monitoring uses macOS kernel events to detect changes — it does not open or modify any Things 3 files

## Tech Stack

- **SwiftUI** with NavigationSplitView
- **GRDB** for local SQLite storage
- **CloudKit** + CKSyncEngine for iCloud sync
- **EventKit** for calendar integration
- **XcodeGen** for project generation
- **macOS 26** (Tahoe) target
- **Swift 6** with strict concurrency

## Architecture

- **Things 3 data**: read-only access to `~/Library/Group Containers/JLMPQHK86H.com.culturedcode.ThingsMac/` with live WAL file monitoring for real-time updates. Area is inherited from project via a COALESCE query.
- **Schedule data**: separate SQLite database at `~/Library/Application Support/TimeboxForThings3/schedule.sqlite`
- **Calendar data**: EventKit with `EKEventStoreChanged` observation for live updates
- **Task source abstraction**: the `TaskProvider` protocol means swapping in another task source (Todoist, etc.) is straightforward
- **App Sandbox enabled**: ready for Mac App Store distribution. Database access uses security-scoped bookmarks granted by the user via NSOpenPanel.

## Building

```bash
# Install XcodeGen if needed
brew install xcodegen

# Generate the Xcode project
xcodegen generate

# Build from command line
xcodebuild -project TimeboxForThings3.xcodeproj -scheme TimeboxForThings3 -destination 'platform=macOS' build
```

For iCloud sync, build from Xcode with your Apple Developer account configured for code signing and CloudKit.

### Demo mode

For screenshots and previews, set the `SLOTTED_DEMO=1` environment variable in the Xcode scheme. The app will load with curated demo data instead of reading your real Things 3 database.

## Requirements

- macOS 26 (Tahoe)
- Things 3 installed
- Xcode 16.3+
