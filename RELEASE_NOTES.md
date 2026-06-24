# Wordled — Release Notes

All notable changes to Wordled are recorded here, newest first. Versions follow
[semantic versioning](https://semver.org/). The in-app version is defined in
`lib/version.dart` and surfaced in **Settings → About / Updates**.

## [1.9.0] — 2026-06-24

### Changed
- **Reworked statistics to be global and comprehensive.** Stats now count
  **every** finished game — any word length, any guess count, daily or new-word
  (previously only daily games were recorded, so "New Word" games didn't count
  at all). Added tracking for:
  - Average guesses per win.
  - **Solve time** (first guess → last guess): average and best.
  - **Hints used** (total).
  - A **per-word-length** played/won breakdown.
  The guess-distribution histogram now adapts to whatever guess counts you've
  actually won in. Streaks are now consecutive wins across all games.

## [1.8.2] — 2026-06-24

### Changed
- **Removed the Content-Security-Policy header.** It was the only thing left that
  differed from the working scrabble-offline PWA, and Chrome wasn't offering the
  install prompt with it in place. Dropped it (and relaxed X-Frame-Options to
  SAMEORIGIN) so installability matches the reference app. The other security
  headers remain.
- On Android/desktop, a tap on "Install App" with no prompt available now shows
  a brief hint to use the browser's own install option instead of the full
  step-by-step dialog (which is kept for iOS).

## [1.8.1] — 2026-06-24

### Fixed
- **"Install App" now actually installs (web).** The `beforeinstallprompt` event
  was being captured from Dart in `InstallService.init()`, which runs only after
  the Flutter engine boots — far too late, so Chrome's early-fired event was
  always missed and the button fell back to the instructions dialog. The event
  is now captured in plain JS in `index.html` at page load (and the Dart service
  calls those helpers), so the native install prompt fires. This was unrelated
  to Vercel Deployment Protection.

## [1.8.0] — 2026-06-24

### Added
- **Native Android app.** Added an Android build target so Wordled can be
  installed as a real local app (no browser). The web-only update/install
  services are now behind platform-conditional imports with native stubs, so the
  same codebase compiles for both web and Android. Launcher icons are generated
  from the app icon.
- **CI APK build** (`.github/workflows/build-apk.yml`): builds a sideloadable
  release APK on GitHub's runners (which can reach the Android SDK/Maven hosts,
  unlike the dev sandbox) and publishes it to the rolling `apk-latest` GitHub
  Release.

## [1.7.1] — 2026-06-24

### Changed
- **Install flow** improved. "Install App" now triggers the native install
  prompt where available (Android / desktop Chrome & Edge) and otherwise shows
  clear, platform-specific steps — including the manual Safari "Add to Home
  Screen" instructions for iOS, which has no install prompt. Added a manifest
  `id` for a stable install identity.

## [1.7.0] — 2026-06-23

### Added
- **Win confetti** scaled to performance — a first-try win rains a big burst,
  tapering down to a modest one at the last allowed guess (dependency-free, and
  skipped under the Battery Saver theme).
- **Loss flow** — finishing without solving now shows an encouraging message and
  a prominent **New word** button to play again with a fresh word.

### Changed
- All large numbers (statistics, guess distribution, dictionary word counts,
  daily puzzle number) are now formatted with thousands separators.

## [1.6.0] — 2026-06-23

### Changed
- **Hints simplified.** A hint now always flashes a random keyboard letter that
  appears in the word (and isn't already solved). The board-arrow hint was
  removed.
- **Invalid keys.** Absent keyboard letters no longer get a diagonal strike;
  they're just rendered in a dimmer letter color.

### Added
- **Diagonal gradients** on the background, the keyboard keys, and the filled
  board tiles for a bit more depth/life.

## [1.5.1] — 2026-06-23

### Fixed
- **Offline / airplane mode never worked.** Flutter 3.44's bootstrap stopped
  registering the service worker on a first visit (it only re-activates an
  already-registered one), so the offline cache was never populated. We now
  register `flutter_service_worker.js` ourselves from `index.html`. The precache
  step was also made resilient (per-resource, via `allSettled`) so one failed
  request can't abort the whole install, and dotfiles are no longer precached.
  Load the app online once after this update, then it works in airplane mode.

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
