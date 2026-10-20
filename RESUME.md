# RESUME — read this first

Project: Ember (macOS Pomodoro timer). Dir: /Users/karthik/claude/ios/Ember
Plan: PLAN.md. Design: design/mocks.html (+ DESIGN.md once a direction is picked).

## State
- Done: M0-M5 (plan, mocks -> chose Tape + rolling numerals, core engine, app shell, popover, main window, motion). M6 mostly done.
- UI verification: `build/Ember.app/Contents/MacOS/Ember --snapshot <dir>` renders PNGs headlessly (ImageRenderer). screencapture returns black here (no permission). Menu/TextField show as yellow "prohibited" boxes in snapshots: render artifact only.
- Drag/haptics/animation can't be exercised headlessly; be honest about that in RUN.md / final report.

## Environment gotchas
- Xcode.app installed but license NOT accepted (needs user's `sudo xcodebuild -license accept`). scripts/env.sh handles it: falls back to CLT and borrows Xcode's macro plugins via -plugin-path (CLT lacks SwiftUIMacros/TestingMacros). ALWAYS `source scripts/env.sh` (or use scripts/*.sh) before swift/git; for git alone, `export DEVELOPER_DIR=/Library/Developer/CommandLineTools`.
- XCTest unavailable under CLT; tests use Swift Testing. Run `scripts/test.sh`.
- Auto-resume cron (every ~30 min, session-only, 7-day expiry) re-enters from this file.

## Next action
None required: M0-M9 complete, RUN.md written. Optional follow-ups if the user reports issues: live-screen check of drag feel, notifications, launch-at-login, Dock progress; reduced-motion for the tape spring; global hotkey; Shortcuts integration (Red Hot Timer parity).

## Log
- 2026-10-20: plan, core, mocks opened in browser, UI built, snapshots verified.
- 2026-10-20: M7 focus mode + scenario editor, M8 stats/dock/login item, M9 icon + RUN.md. Auto-resume cron deleted.
