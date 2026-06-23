# Wordled — Release Notes

All notable changes to Wordled are recorded here, newest first. Versions follow
[semantic versioning](https://semver.org/). The in-app version is defined in
`lib/version.dart` and surfaced in **Settings → About / Updates**.

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
