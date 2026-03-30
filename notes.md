# Timebox for Things 3 — Project Notes

## App Concept

A native macOS app that reads Things 3 task data and presents a timeboxing/day planner UI. Thematically similar to Things 3's visual style. Potentially extensible to other task managers (Todoist, etc.).

### Two-Panel UI

**Left-Hand Side (LHS) — Task List**
- Shows all unscheduled tasks grouped by date category: Inbox, Overdue (red), Today, Tomorrow, This Week, Later, This Month, future months, and Someday
- Inbox tasks always appear regardless of the active nav filter
- Tasks stay in the LHS even after being scheduled on the RHS (you can drag the same task to multiple time slots)
- Each task card shows project name, tags, due date, status indicator, and notes indicator (controlled by display settings)
- The LHS is resizable by dragging its right edge
- Tags can be dragged from the sidebar onto LHS task cards

**Right-Hand Side (RHS) — Schedule Grid**
- Vertical time grid with 30-minute slots
- Configurable start/end hours (default 9 AM – 5 PM) via Settings
- Time labels on the left edge at each hour mark
- A "now line" shows the current time when the app is open
- Today's date displayed at the top

**Two types of blocks on the RHS:**

1. **Task blocks** — created by dragging a task from the LHS onto a time slot. Shows task title, project name, status indicator (top-right, hidden on hover when × appears), notes indicator (bottom-right), meta info (time range, due date, checklist count), and tags. Color matches the task's project color. Linked to the task — completing the task removes the block.

2. **Standalone time blocks** — created by double-clicking an empty slot. For non-task activities like Lunch, School pickup, Meetings. Shows title (italic), color dot (top-left, click to cycle colors), × to remove. Title editable by double-clicking. Dotted left border distinguishes them from task blocks.

**Block interactions:**
- Drag to move to a different time slot
- Resize by dragging top or bottom edge
- × button removes the block (appears on hover, hides status indicator)
- Click opens the detail panel (task blocks only)
- Right-click for context menu (task blocks only)
- Tags can be dragged onto task blocks from the sidebar

**Persistence:**
- All blocks persist across days by default (task blocks and standalone)
- "Clear schedule daily" setting (off by default) deletes old task blocks at midnight
- Completing/cancelling a task removes all its scheduled blocks

**Summary bar** at the top shows: scheduled task count, total planned hours, and free hours remaining. Red indicator if overcommitted.

---

## Things 3 Data Access — Research (2026-03-30)

### Officially Supported by Cultured Code

**AppleScript** — Fully documented and officially supported:
- [Using AppleScript - Things Support](https://culturedcode.com/things/support/articles/2803572/)
- [Things AppleScript Commands](https://culturedcode.com/things/support/articles/4562654/)
- [AppleScript PDF Guide](https://culturedcode.com/things/download/Things3AppleScriptGuide.pdf)
- Read AND write access: create/read/update/delete to-dos, projects, areas, tags, scheduling, etc.
- Mac only. Cultured Code recommends Apple Shortcuts for cross-platform.
- Caveat: "Not all of Things' features are accessible via AppleScript; if it's not documented, it's not possible."
- Caveat: "We cannot provide assistance with writing or troubleshooting custom scripts."

**URL Scheme** — Also officially documented:
- [Things URL Scheme](https://culturedcode.com/things/help/url-scheme/)
- Mostly for writing/creating tasks, limited for reads.

**SQLite Database Access** — Explicitly facilitated:
- On their [official data export page](https://culturedcode.com/things/support/articles/2982272/), Cultured Code tells users they can access their data as a SQLite database file.
- They even recommend third-party SQLite viewer apps (e.g., Base 2).
- Framed under GDPR data access rights.
- Database location: `~/Library/Group Containers/JLMPQHK86H.com.culturedcode.ThingsMac/Things Database.thingsdatabase/main.sqlite`

### Things Cloud Terms of Service

The [Things Cloud ToS](https://culturedcode.com/terms/) prohibit:
- Reverse engineering the **cloud service** or its protocols
- Accessing the **cloud service** by means other than "publicly supported interfaces"

**Important:** These ToS apply specifically to Things Cloud (their sync service), NOT to the local app or its local database.

### Community Precedent

There is a healthy ecosystem of third-party projects reading the Things 3 database directly, and Cultured Code has not objected to any of them:
- [things.py](https://github.com/thingsapi/things.py) — Python library to read Things data via SQLite
- [things-api](https://github.com/evelion-apps/things-api) — Unofficial GraphQL API
- [things3-export](https://github.com/bboc/things3-export) — Export to TaskPaper format
- [pythings](https://github.com/mdbraber/pythings) — Python interface using SQLite + peewee ORM
- [things3-api on PyPI](https://pypi.org/project/things3-api/) — CLI, API, and Web Service with Kanban view

### Recommended Approach

| Method | Status | Use For |
|--------|--------|---------|
| **AppleScript** | Officially supported | Writing back to Things (complete tasks, update) |
| **Local SQLite (read-only)** | Explicitly facilitated by CC | Fast bulk reads of all tasks |
| **Things Cloud API** | Off limits | Don't touch their cloud service |

The hybrid approach (SQLite reads + AppleScript writes) respects their boundaries: reading a local database they tell users how to find, and writing through their official scripting interface.

**Caveat:** The SQLite schema is undocumented and could change between versions, but the community has tracked it for years and it's been quite stable.

---

## Design Philosophy

The app is intended to be used **side-by-side with Things 3**. It should faithfully recreate the look and feel of Things 3 — if you squint, they should look like twins. Same visual language: typography, spacing, color palette, iconography style, subtle animations, and overall aesthetic. The goal is that a Things 3 user feels immediately at home, as if this were a native extension of the app.

Of course, this must be done **without infringing Cultured Code's IP** — inspired by, not copied from. Use the same design principles (clean, minimal, lots of whitespace, soft colors, elegant typography) rather than pixel-copying their assets.

### Visual Reference (from Things 3 screenshots, 2026-03-30)

Screenshots saved in `/Screenshots/` folder. Key observations:

**Overall:** Far more minimal than typical task apps. The design is defined by what's NOT there.

**Sidebar:**
- Warm off-white/cream translucent background (glass effect)
- Fixed nav at top: Inbox (blue tray), Today (gold star), Upcoming (red calendar), Anytime (teal circles), Someday (amber icon) — colorful SF Symbol-style icons
- Logbook, Trash below nav
- Areas as **bold section headers**, projects as indented regular-weight text
- Selected item = soft blue highlight pill
- ~13pt SF Pro

**Task rows (NOT cards):**
- Simple rows — no borders, no shadows, no card backgrounds
- Thin-stroke open circle checkbox (~18px diameter) on left
- Title in regular-weight SF Pro (~14pt, near-black)
- Right-aligned deadline metadata in small gray text ("Apr 19", "1 day left")
- Very generous vertical spacing between items

**Project groupings in Today view:**
- Project name as bold section header with small colored filled circle to its left
- Tasks listed flat below

**Upcoming view:**
- Date sections: large bold day number + day name ("31 Tomorrow")
- Tasks show title + project name below in smaller gray text

**Project view:**
- Large bold project title with icon
- Date labels (gray) on left edge before checkboxes
- "Hide later items" / "Show N logged items" as subtle text links

**Typography:** SF Pro throughout. Bold headings (~24pt), semibold section headers, regular task titles, lighter gray metadata.

**Colors:** Almost monochrome. Color only in: sidebar nav icons, project heading circles, deadline warnings. Everything else is black-on-white or gray. Extremely restrained.

---

## Architecture Decisions (Open)

### Tech Stack
- **SwiftUI** for UI (native macOS, matches Things 3 aesthetic)
- **AppKit** where needed (drag-and-drop, resize handles, custom grid drawing)
- **GRDB or SQLite.swift** for reading the Things DB
- **NSAppleScript or JXA bridge** for write operations

### Task Provider Abstraction
```
TaskProvider (protocol)
  ├── Things3Provider (SQLite reads + AppleScript writes)
  ├── TodoistProvider (REST API)
  └── ...future providers
```

### Resolved (v1)
- **Tech stack:** SwiftUI + GRDB.swift, no AppKit needed so far
- **Data access:** SQLite read-only + file system monitoring (WAL watcher via DispatchSource)
- **Schedule storage:** Separate local SQLite via GRDB
- **Scope:** Core two-panel view, read-only (no write-back to Things 3 yet)

### Future Work
- **Dark mode support** — Things 3 has full dark mode (screenshot in `/Screenshots/`). Dark mode colors: dark charcoal/near-black content background, slightly lighter sidebar, same minimal styling inverted. Our app should follow the system appearance and match Things 3's dark palette.
- **Write-back to Things 3** via AppleScript (complete tasks, update status)
- **Todoist provider** (REST API backend)
- **Settings UI** (configurable start/end hours, clear schedule daily toggle)
- **Multi-day view** (navigate between dates)
- **Resizable split view** (replace HStack+Divider with proper draggable divider)
