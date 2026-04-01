# Slotted

A native macOS time blocking companion for [Things 3](https://culturedcode.com/things/).

Things 3 is great for managing tasks but lacks a way to plan your day on a timeline. Slotted reads your Things 3 tasks and lets you drag them onto a visual schedule grid.

## Features

### Task List (Left Panel)
- Live read-only access to your Things 3 database
- Tasks grouped by Things 3 categories: Inbox, Today, Upcoming, Anytime, Someday
- Area / Project hierarchy within each category with expand/collapse controls
- Sorted by start date, then deadline, then alphabetically
- Deadline indicators with red calendar icon
- Completed tasks automatically removed from the schedule
- Option to hide or keep tasks visible after scheduling

### Schedule Grid (Right Panel)
- Drag tasks from the list onto the timeline
- Single-gesture interaction: drag from top edge to resize start, bottom edge to resize end, middle to move
- Smooth drag follow with snap-to-grid on release (15-minute increments)
- Custom block colors: click the color dot on hover to cycle through 10 colors
- Standalone time blocks (double-click to create, e.g., "Lunch", "Meeting")
- Multi-timebox: schedule the same task in multiple time slots (e.g., before and after lunch)
- Arrow keys to nudge selected blocks by 15 min, Delete key to remove
- Drop target highlight when dragging from the task list
- Now line showing current time
- Blocks clamp to visible schedule bounds

### Calendar Integration
- Import events from macOS calendars and display on the schedule
- Calendar events shown with diagonal hatching pattern, accent bar in calendar color
- Visually distinct from task blocks (read-only, no drag/resize)
- Auto-refreshes when calendar changes
- Toggle on/off in Settings

### Settings
- Schedule hours (start/end)
- Text size slider
- Light/Dark/Auto appearance
- Hide empty categories
- Hide scheduled tasks (toggle off for multi-timebox)
- Show/hide deadlines
- Show calendar events
- Clear schedule at midnight (when off, blocks carry forward to the next day)
- iCloud Sync on/off

### iCloud Sync
- Sync schedule data across devices via CloudKit
- Uses CKSyncEngine for reliable, offline-capable sync
- Conflict resolution with persisted server record caching
- Simple toggle — no account setup needed

## Tech Stack

- **SwiftUI** with NavigationSplitView
- **GRDB** for local SQLite storage
- **CloudKit** + CKSyncEngine for iCloud sync
- **EventKit** for calendar integration
- **XcodeGen** for project generation
- **macOS 26** (Tahoe) target
- **Swift 6** with strict concurrency

## Architecture

- **Things 3 data**: read-only access to `~/Library/Group Containers/JLMPQHK86H.com.culturedcode.ThingsMac/` with live WAL file monitoring for real-time updates. Area inherited from project via COALESCE query.
- **Schedule data**: separate SQLite database at `~/Library/Application Support/TimeboxForThings3/schedule.sqlite`
- **Calendar data**: EventKit with EKEventStoreChanged observation for live updates
- **Task source abstraction**: designed to be extensible to other task managers (Todoist, etc.)

## Your Things 3 Data is Safe

Slotted uses **read-only access** to your Things 3 database. It cannot modify, delete, or corrupt your data.

- The database connection is opened with SQLite's `SQLITE_OPEN_READONLY` flag — write attempts are rejected at the database engine level
- There are no write statements (INSERT, UPDATE, DELETE) against the Things 3 database anywhere in the codebase
- Your schedule is stored in a completely separate database
- File monitoring uses macOS kernel events to detect changes — it does not open or modify any Things 3 files

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

## Requirements

- macOS 26 (Tahoe)
- Things 3 installed
- Xcode 16.3+
