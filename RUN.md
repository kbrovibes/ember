# Run Ember

Location: `/Users/karthik/claude/ios/Ember`

## Quick start

```sh
cd /Users/karthik/claude/ios/Ember
scripts/run.sh
```

Builds a release binary, assembles `build/Ember.app` (ad-hoc signed), and launches it. First build takes ~30s.
Ember shows in the **menu bar** (flame icon) and opens its main window. Click the menu-bar icon for the popover.

Install permanently: `cp -R build/Ember.app /Applications/`

## Using it

One window, one idea: timers. A Pomodoro is just a `focus 20min` timer.

| Do this | To |
|---|---|
| Type in the big line, e.g. `water 2m`, `focus 20min`, `20 min focus`, `tea 1h30m`, `eggs 90s` + Return | Start a timer. Name and time are pulled out of the sentence |
| Tap a chip under the line | Start that named timer again. Seeded with Focus 20m, Water 1h, Break 5m; named timers you add are remembered and the most-used show first. Right-click a chip to remove it |
| Edit a card's name; pause/resume, reset, × | Manage each timer. Cards shrink to fit, never scroll |
| ✓ or ↻ on a finished card | ✓ stops the alarm and closes the timer; ↻ restarts it. Finished timers ring every ~2s until you press one |
| Expand button (top right), or idle for 10 minutes | Distraction-free mode: only the timers, filling the window. Faint exit button top right, or Esc. A finished timer keeps its ✓ / ↻ buttons. Turn the auto-switch off in Settings |
| Order / A–Z / Time left / Length tabs (top left, with 2+ timers) | Sort timers; click the active one again to reverse |
| Settings → Timer glyphs | Optional per-timer personality: Symbol, Monogram, Pattern or Buddy (a face that blinks and beams when done). Same name, same look. Off turns it off |
| Chart button | Stats: finished timers today, streak, last 7 days |
| ⌘, or gear button | Settings: timer theme (Halo, Mono, Tide, Cinder, Tape — switches live, no restart), mode (light default) + accent colour, alarm sound + volume, notifications, menu-bar countdown, launch at login, data folder |

Closing the window keeps Ember (and your timers) running in the menu bar; the Dock icon reopens it. Quit with Dock right-click → Quit, the popover's Quit, or ⌘Q.
The menu bar shows the soonest-finishing timer; the Dock icon shows its progress.

## Files

- `design/mocks.html` — the 5 design directions (open in browser). Chosen: **Tape + rolling numerals** (`DESIGN.md`).
- `PLAN.md`, `RESUME.md` — milestones and resume notes.
- Data: `~/Library/Application Support/Ember/` (`history.json` = finished timers, `state.json` = timers and quick-start usage). Preferences are in UserDefaults.

## Develop

```sh
scripts/test.sh                                   # unit tests (Swift Testing)
scripts/bundle.sh debug                           # build without launching
build/Ember.app/Contents/MacOS/Ember --snapshot /tmp/shots   # render screens to PNG, headless
swift scripts/make-icon.swift && iconutil -c icns build/AppIcon.iconset -o Resources/AppIcon.icns   # regenerate icon
```

## Xcode license (optional)

Xcode is installed but its license isn't accepted, so the stock `swift`/`git` shims fail. `scripts/env.sh` works around this
(Command Line Tools + Xcode's macro plugins), so everything above works as is. To remove the workaround:

```sh
sudo xcodebuild -license accept
```

For plain `git`/`swift` in your own shell before that, run `export DEVELOPER_DIR=/Library/Developer/CommandLineTools`.

## Not yet verified by hand

Built and checked headlessly (unit tests, launch-without-crash, rendered screenshots). Not exercised on a live screen:
drag/haptics feel, notification delivery (macOS asks permission on first alert), launch at login, Dock progress bar.
If any misbehaves, note it in `RESUME.md`.
