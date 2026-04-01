# TODO

## Mac App Store Distribution
- Current approach reads Things 3's SQLite DB directly via hardcoded group container path
- App Sandbox (required for MAS) blocks access to other apps' containers
- Needs sandbox-compatible solution (URL scheme, AppleScript, user-granted file access)
- Handle all install scenarios: Things 3 not installed, installed after, Setapp version
- Design graceful onboarding UX for all cases
