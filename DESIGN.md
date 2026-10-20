# Ember — design decision

Mocks: `design/mocks.html` (5 directions). Tokens: `design/tokens.json` (source of truth for values).

**Chosen: Tape** (draggable tick ruler for setting/showing time) **+ Mono's rolling numerals** for the clock.
Why: dragging a ruler is the most physical way to set time; each minute is a detent (haptic-capable); scales from 320pt popover to fullscreen. Trade-off: less glanceable than a ring, offset by big numerals and the cycle strip.

## Rules
- Light by default (user preference); dark follows tokens; appearance selectable in Settings.
- One accent per phase: focus ember `#CC4317`, short break teal `#2C7A8C`, long break indigo `#5A5FB8`. Never colour alone: label + SF Symbol + strip position (flame / cup / moon).
- Time: monospaced digits, light weight, `.numericText` rolling transition.
- Motion: `spring(response: 0.39, dampingFraction: 0.81)` for follow/press; 0.7s colour shift between phases; reduced-motion respected (no spring/rolling, 0.12s crossfade).
- Tape: 10pt per minute, 1:1 while dragging, projected release (30% of predicted travel) then spring-snap to nearest minute; haptic `.alignment` every 5 minutes.
- Ranges: focus 1–90, short 1–30, long 5–60.
- Surfaces: popover 320pt wide; main window 840×540 (min 640×420); fullscreen focus mode with controls fading to 0.22 opacity.
