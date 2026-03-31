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

## Show Area with Project Names
- LHS project group headers currently only show the project name
- Should also show the area (e.g., "Work > Hope IP - Firm Stuff" or "Personal > Financial")
- Things 3 organizes projects under areas — our UI should reflect that hierarchy

## iCloud Sync Polish
- Persist server record cache to disk to avoid "record already exists" errors on app restart
- Currently self-healing (retry succeeds) but logs noisy errors in console
