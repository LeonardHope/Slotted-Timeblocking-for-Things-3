# Timebox for Things 3

A native macOS companion app for [Things 3](https://culturedcode.com/things/) that adds timeboxing and day planning.

Things 3 is great for managing tasks but lacks a way to plan your day on a timeline. This app reads your Things 3 tasks and lets you drag them onto a visual schedule grid.

## Features

### Task List (Left Panel)
- Live read-only access to your Things 3 database
- Tasks grouped by Things 3 categories: Inbox, Today, Upcoming, Anytime, Someday
- Tasks organized by project within each category
- Sorted by start date, then deadline, then alphabetically
- Deadline indicators with calendar icon
- Tasks hide from the list when scheduled on the timeline

### Schedule Grid (Right Panel)
- Drag tasks from the list onto the timeline
- Single-gesture interaction: drag from top edge to resize start, bottom edge to resize end, middle to move
- Smooth drag follow with snap-to-grid on release (15-minute increments)
- Standalone time blocks (double-click to create, e.g., "Lunch", "Meeting")
- Arrow keys to nudge selected blocks, Delete key to remove
- Drop target highlight when dragging from the task list
- Now line showing current time

### Settings
- Schedule hours (start/end)
- Text size slider
- Light/Dark/Auto appearance
- Hide empty categories
- Show/hide deadlines
- Clear schedule at midnight (auto-clears previous day's blocks)
- iCloud Sync on/off

### iCloud Sync
- Sync schedule data across devices via CloudKit
- Uses CKSyncEngine for reliable, offline-capable sync
- Conflict resolution with server record caching
- Simple toggle — no account setup needed

## Tech Stack

- **SwiftUI** with NavigationSplitView
- **GRDB** for local SQLite storage
- **CloudKit** + CKSyncEngine for iCloud sync
- **XcodeGen** for project generation
- **macOS 26** (Tahoe) target
- **Swift 6** with strict concurrency

## Architecture

- **Things 3 data**: read-only access to `~/Library/Group Containers/JLMPQHK86H.com.culturedcode.ThingsMac/` with live WAL file monitoring for real-time updates
- **Schedule data**: separate SQLite database at `~/Library/Application Support/TimeboxForThings3/schedule.sqlite`
- **Task source abstraction**: designed to be extensible to other task managers (Todoist, etc.)

## Your Things 3 Data is Safe

Timebox for Things 3 uses **read-only access** to your Things 3 database. It cannot modify, delete, or corrupt your data.

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
