# Wordled — Release Notes

All notable changes to Wordled are recorded here, newest first. Versions follow
[semantic versioning](https://semver.org/). The in-app version is defined in
`lib/version.dart` and surfaced in **Settings → About / Updates**.

## [1.5.0] — 2026-06-23

### Added
- **Dictionary settings.** A new Settings section shows the word count for the
  current length ("N valid · M possible answers") and an **Update word list**
  button that reloads the offline dictionary from the bundle.

### Fixed
- The **hint icon** is now always visible; the button stays enabled and reports
  why a hint isn't available (game over / none left) instead of greying out the
  icon while still showing the count badge.

### Changed
- How To Play no longer mentions the daily-puzzle schedule.

### Security
- Added hardening HTTP headers on every response (Content-Security-Policy,
  X-Frame-Options: DENY / frame-ancestors 'none', X-Content-Type-Options,
  Referrer-Policy, Permissions-Policy, Cross-Origin-Opener-Policy). See the
  pen-test review notes in the commit/PR discussion. Added clarifying security
  comments in the storage and service-worker code.

## [1.4.1] — 2026-06-23

### Changed
- Absent keyboard keys are now indicated by a darkened key color plus a faint
  (50% opacity) diagonal line across the key, instead of a strikethrough on the
  letter.

## [1.4.0] — 2026-06-23

### Added
- **Placement icons on the board.** Evaluated tiles now show a small check on
  correctly-placed letters and a dot on present-but-misplaced letters — a
  color-blind-friendly cue shown on every theme.
- **Struck-through keyboard letters.** Letters confirmed absent are now drawn
  with a line through them on the keyboard.
- **Three new themes:** Low Light (dimmed, easy-on-the-eyes dark), Monochrome
  (grayscale; leans on the placement icons), and Battery Saver (pure-black OLED
  theme that also disables board animations to save power).
- **Hint feature.** A 💡 hint button next to the Statistics icon. Each hint
  either flashes a useful keyboard letter or flashes an arrow on a misplaced
  letter on the board. Hints per game are configurable in Settings
  (0–5, default 3) and the button shows the remaining count.

### Changed
- Tile and key text now auto-picks black/white for contrast, so light palette
  colors (e.g. Monochrome) stay legible.
- How To Play updated to document the placement icons, struck-through keys, and
  the hint button.

## [1.3.1] — 2026-06-23

### Changed
- The drawer header subtitle now reads "Offline · v<version>" (shows the
  running app version) instead of "Offline word game".

## [1.3.0] — 2026-06-23

### Changed
- **Navigation simplified.** Removed the top-right overflow menu; all
  navigation now lives in the left drawer (the quick Statistics icon remains in
  the app bar).
- The drawer's game action is now **New Word** (starts a fresh random word),
  replacing the separate "Daily puzzle" and "Practice" entries.

### Added
- The drawer shows **Install App** until the PWA is installed; once it's running
  as an installed standalone app, that entry becomes **Check for Update**
  (queries the service worker and offers to reload when a new version is ready).

## [1.2.0] — 2026-06-23

### Fixed
- **Blank text / invisible letters.** The CanvasKit web renderer was relying on
  a CDN-hosted default font, so on the deployed site every glyph (keyboard
  letters, typed tiles, app-bar icons) rendered invisibly. Roboto is now
  bundled as an asset and set as the default font family, so all text renders —
  online and offline.

### Added
- **Overflow menu** in the top-right of the app bar with: New game, Settings,
  How to play, and **Install app** (triggers the PWA "Add to Home screen"
  prompt, with manual instructions as a fallback).

## [1.1.0] — 2026-06-23

### Added
- **Configurable board.** Word lengths from **3 to 9 letters** and guess counts
  from **4 to 20**, chosen in Settings. Per-length dictionaries are bundled as
  assets so every size works offline.
- **Settings page** with:
  - Theme picker (System / Light / Dark).
  - Palette presets (Classic, High Contrast, Dark Forest, Candy, Ocean) plus a
    **Custom palette** editor for the correct / present / absent colors.
  - Difficulty picker (Easy / Normal / Hard). Hard enforces that revealed hints
    are reused; Easy relaxes dictionary checking.
  - Word length and guess-count selectors.
- **How To Play** page rebuilt to mirror the official layout, with worked
  colour examples.
- **Update & maintenance center** (Settings → Updates) with:
  - Verbose, timestamped diagnostic logging and an in-app log viewer.
  - App version tracking that logs upgrades between runs.
  - **Check for updates** that talks to the service worker and applies a waiting
    update.
  - **Clear cache** that purges all service-worker caches and reloads.
  - **Nuclear reset** that obliterates caches, the service worker, and all saved
    data, returning the app to a first-run state.
- Per-configuration statistics and daily progress (each board size tracks its
  own streaks and distribution).

### Changed
- Word lists moved from a compiled-in Dart file to bundled text assets loaded on
  demand by `WordRepository`.
- App-bar icons rearranged to match the reference (hint placeholder, stats,
  help, settings); keyboard keys given slightly more rounded corners.

## [1.0.0] — 2026-06-23

### Added
- Initial Wordled: offline-first Flutter web build of Wordle.
- Daily puzzle (deterministic from the date) and random practice mode.
- 6×5 board with flip / pop / shake animations and a colour-coded keyboard.
- Local statistics, emoji share, high-contrast toggle.
- Offline service worker (`tool/gen_service_worker.js`) and Vercel deployment
  config so the installed PWA plays in airplane mode.
