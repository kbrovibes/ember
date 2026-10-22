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

| Do this | To |
|---|---|
| Drag the ruler sideways (idle) | Set duration (10 pt = 1 min, haptic every 5 min) |
| Type in the popover field: `25`, `1h30m`, `90s`, `5m/1m #deep` | Set duration by text |
| `Space` | Start / pause |
| Skip / reset buttons | Move to next phase / restart this one |
| Preset menu → Edit scenarios… | Pick or build your own focus/break cycle (saved) |
| Expand button (main window) | Fullscreen focus mode; controls fade while running; `Esc` exits |
| Grid button (main window) | Timers: any number of independent countdowns in a grid. Type `5m #tea` + Return to add; play/pause, reset, remove per card. Not saved across launches |
| Chart button (main window) | Stats: today, streak, last 7 days |
| ⌘, | Settings: appearance (light by default), auto-start, sound, notifications, launch at login |

Phases: Focus (ember red, flame) → Short break (teal, cup) → Long break (indigo, moon). Never colour-only: label and icon change too.
Dock icon shows a progress bar while a timer runs.

## Files

- `design/mocks.html` — the 5 design directions (open in browser). Chosen: **Tape + rolling numerals** (`DESIGN.md`).
- `PLAN.md`, `RESUME.md` — milestones and resume notes.
- Data: `~/Library/Application Support/Ember/` (`history.json`, `presets.json`).

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
