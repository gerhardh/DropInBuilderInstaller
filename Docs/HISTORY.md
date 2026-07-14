# HISTORY

Append-only changelog. Newest entries at the top.

## 2026-07-05

- Set the app's copyright string.
- Stopped tracking Finder / Xcode UI-state cruft (`.DS_Store`, per-user
  scheme and workspace state) in the repository.

## 2026-04-21

- Stripped the universal rules from `CLAUDE.md`, leaving only
  project-specific content (universal rules now live in `~/.claude/CLAUDE.md`).

## 2026-03-28

- Updated `CLAUDE.md` guidance.

## 2026-03-25

- Added build & install functionality with UI.
  - `BuildManager` (actor): detects project type (`Package.swift`,
    `.xcworkspace`, `.xcodeproj`) and drives a build helper script,
    streaming output back to the UI without pipe-buffer deadlock.
  - `ScriptInstaller`: writes the bundled `build.sh` helper into
    `~/Library/Application Scripts/de.dieheidkamps.DropInBuilderInstaller`
    via an `NSSavePanel` prompt, so builds can run outside the sandbox.
  - `Installer`: helper that copies a built `.app` into `~/Applications`.
  - `BookmarkManager`: saves and restores a security-scoped bookmark for
    the selected project folder.
  - `ContentView`: folder selection, live build log, and
    Build & Install / Clear & Rebuild actions.
  - `AppDelegate`: opens a folder passed to the app via URL / drop.
- Initial commit: Xcode project scaffold, assets, and entitlements
  (`app-sandbox`, `files.user-selected.read-write`,
  `files.bookmarks.app-scope`).
