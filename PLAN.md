# Ember — plan

Minimal, "buttery" Pomodoro timer for macOS (SwiftUI, macOS 14+), inspired by Red Hot Timer.
Menu-bar first, drag-to-set time, text shorthand (`25m`, `5m/1m`, `#focus`), scenarios (sequences).

## Constraints
- Toolchain: SwiftPM + Command Line Tools (Swift 6.4). Full Xcode may finish installing later; nothing here depends on it. No `xcodebuild`.
- App bundle is assembled by `scripts/bundle.sh` (ad-hoc signed). Run with `scripts/run.sh`.
- Light mode default. Self-contained. No third-party deps.
- Commit after every milestone (local git only, never push).

## Milestones (each ends in a commit)
| ID | Milestone | Status |
|----|-----------|--------|
| M0 | Repo, plan, resume protocol | done |
| M1 | UX designer mocks (5 directions) opened in browser; pick one; write DESIGN.md | done |
| M2 | EmberCore: engine state machine, presets, input parser + tests | done |
| M3 | App shell: MenuBarExtra + window, bundle/run scripts, runs as .app | done |
| M4 | Menu-bar popover UI + drag-to-set interaction | done |
| M5 | Main window timer face + motion (springs, state transitions) | done |
| M6 | Break/long-break cycle, notifications, sounds, menu-bar countdown | done (alerts/delivery not verified on a live screen) |
| M7 | Fullscreen focus mode, scenario editor, persistence | done |
| M8 | Stats/history, settings, launch at login, Dock progress | done |
| M9 | Polish: icon, a11y, reduced motion, RUN.md, final verification | done |

## Definition of done
`scripts/run.sh` builds and launches Ember.app; a full 25/5 cycle works; UI matches chosen design; RUN.md accurate; `swift test` green.

## Resume protocol
Read `RESUME.md` first (current state + next action). Do the next unchecked milestone, commit, update `RESUME.md` and the table above.
