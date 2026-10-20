# RESUME — read this first

Project: Ember (macOS Pomodoro timer). Dir: /Users/karthik/claude/ios/Ember
Plan: PLAN.md. Design: design/mocks.html (+ DESIGN.md once a direction is picked).

## State
- M0 done. M1 (mocks) delegated to a designer agent; M2 (core) in progress.
- Xcode was still downloading at start (Xcode.appdownload); build with SwiftPM only.

## Environment gotchas
- Xcode.app is installed but its license is NOT accepted (needs user's `sudo xcodebuild -license accept`). Until then prefix every shell command with `export DEVELOPER_DIR=/Library/Developer/CommandLineTools` (applies to git, swift, codesign shims too).
- XCTest is unavailable under CLT; tests use Swift Testing (`import Testing`). `scripts/test.sh` (retries a flaky TestingMacros plugin load) works.
- An auto-resume cron (every ~30 min, session-only, 7-day expiry) re-enters the work from this file.

## Next action
Finish M2 (swift test green), commit. Then check design/mocks.html exists, open it in the browser, pick a direction, write DESIGN.md, commit. Then M3.

## Log
- 2026-10-20: project created, plan written.
