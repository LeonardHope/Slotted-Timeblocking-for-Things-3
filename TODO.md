# TODO

## Mac App Store Distribution
- Current approach reads Things 3's SQLite DB directly via hardcoded group container path
- App Sandbox (required for MAS) blocks access to other apps' containers
- Needs sandbox-compatible solution (URL scheme, AppleScript, user-granted file access)
- Handle all install scenarios: Things 3 not installed, installed after, Setapp version
- Design graceful onboarding UX for all cases

## Multi-timebox Support
- Setting to keep tasks visible on LHS after scheduling on RHS
- Allow same task to be scheduled in multiple time blocks
- Use case: working on the same task before and after lunch
- Currently tasks hide from LHS after first drag, preventing this

## Custom Block Colors
- Let users change the color of individual task time blocks
- Add a simple control (click-to-cycle dot, like standalone blocks already have)
- Add `colorIndex` field to `TimeBlock` model (needs DB migration)
- Default to current project-based color, override when user picks custom

## Area / Project Hierarchy on LHS
- Within each category, group tasks into areas, then projects under each area
- Add expand/collapse controls for areas and projects
- Hierarchy: Category > Area > Project > Tasks
- Tasks without an area/project go under a default "No Area" group
- Matches how Things 3 organizes its sidebar

## Calendar Integration
- Import events from the user's macOS calendar and show as blocks on the RHS
- Calendar events block out time, preventing task scheduling over meetings
- User-controlled setting to enable/disable
- Use EventKit framework (requires calendar access permission)
- Consider: which calendars to show, read-only vs editable, visual style for calendar blocks vs task blocks
- Auto-refresh when calendar changes

## App Icon Update
- Adjust clock hands: little hand on 10, big hand on 2
- This creates a checkmark shape that mirrors the check in the Things 3 icon
- Subtle nod to Things 3 while keeping the clock/timebox concept

## iCloud Sync Polish
- Persist server record cache to disk to avoid "record already exists" errors on app restart
- Currently self-healing (retry succeeds) but logs noisy errors in console
