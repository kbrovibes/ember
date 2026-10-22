# Design

Ember should feel calm, quick and a little playful. One idea drives it: a timer is a name and a time.

## Principles
- **One window, one idea.** No modes. A Pomodoro is just a `focus 20min` timer.
- **Type, don't configure.** The text line is the main control. It reads sentences: `water 2m`, `20 min focus`.
- **Never scroll, never blur.** Timer cards fill the window by resizing, not by scrolling. Every size is multiplied through layout (never a scaled bitmap) so text and strokes stay sharp at any size.
- **Quiet by default, loud when it matters.** Controls are small and flat. A finished timer pulses and rings until acknowledged.
- **Light by default**, with dark and system modes. One restrained accent (Ember, Plum, Moss or Graphite); glyph colours are close neighbours of the accent.
- **Names are lowercase.**

## Pieces
- **Themes** (how time is drawn): Halo (ring dial), Mono (big numerals + hairline), Tide (draining pill), Cinder (liquid vessel), Tape (ruler under a needle). See `docs/design/mocks.html` for the original explorations.
- **Glyphs** (optional personality): symbol picked from the name, monogram, identicon pattern, or a blinking buddy.
- **Distraction-free mode**: only the timers; a faint exit button; finished timers keep their ✓ ↻.
- **Motion**: `spring(response: 0.39, dampingFraction: 0.81)` for press and follow; a softer spring when cards reflow; Reduce Motion is respected.

Design tokens from the first round live in `docs/design/tokens.json`.
