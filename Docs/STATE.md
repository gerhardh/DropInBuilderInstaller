# STATE

Current components, configuration, and known limitations. Newest at top.

## Overview

DropInBuilderInstaller is a sandboxed macOS (SwiftUI + AppKit) app that takes a
project folder, builds it in Release with `xcodebuild` or Swift Package Manager,
and installs the resulting `.app` into `/Applications`.

## Configuration

- Bundle identifier: `de.dieheidkamps.DropInBuilderInstaller`.
- Marketing version: 1.0.
- macOS deployment target: 26.4 (Tahoe).
- Swift language version: 5.0.
- Entitlements: `com.apple.security.app-sandbox`,
  `com.apple.security.files.user-selected.read-write`,
  `com.apple.security.files.bookmarks.app-scope`.

## Components

- `DropInBuilderInstallerApp.swift` — `@main` App. Hosts `ContentView` in a
  `WindowGroup` (min 700x420). `AppDelegate` handles `application(_:open:)`,
  posting a `.didSelectFolder` notification for URL/drop-opened folders.
- `ContentView.swift` — Main UI: Select Folder button, selected-folder label,
  monospaced build-log text area, and Build & Install / Clear & Rebuild
  buttons. Restores the saved bookmark on appear; listens for
  `.didSelectFolder`.
- `BuildManager.swift` — Actor. Ensures the helper script is installed, detects
  project type (`Package.swift` -> `swiftpm`; `.xcworkspace` ->
  `xcode-workspace`; `.xcodeproj` -> `xcode-project`), then runs the script via
  `NSUserUnixTask`. Reads stdout/stderr with `readabilityHandler` to avoid pipe
  deadlock; parses `BUILD_APP_PATH:`, `INSTALLED:`, and `INSTALL_FAILED:`
  markers. Defines `BuildError` (projectNotFound, buildFailed, appNotFound,
  scriptNotInstalled).
- `ScriptInstaller.swift` — Owns the embedded `build.sh` content and installs it
  (0755) into
  `~/Library/Application Scripts/de.dieheidkamps.DropInBuilderInstaller`
  through an `NSSavePanel`. `isInstalled()` verifies the on-disk script byte-for-
  byte matches the current embedded version, so an outdated script is reinstalled.
  Resolves the real home directory via `getpwuid` (sandbox-container aware).
- `BookmarkManager.swift` — Saves/restores a security-scoped bookmark for the
  selected folder in `UserDefaults` (`selectedFolderBookmark`); refreshes stale
  bookmarks and calls `startAccessingSecurityScopedResource()`.
- `Installer.swift` — Standalone helper that copies an `.app` into
  `~/Applications`. See limitation below.

## build.sh helper actions

- `swiftpm` — `swift build -c release`; optional `swift package clean`; finds the
  first `*.app` under `.build`.
- `xcode-workspace` / `xcode-project` — `xcodebuild -configuration Release` with
  `BUILD_DIR=<project>/build`; optional `clean`; finds the first `*.app` under
  the build dir.
- Both install by copying to `/Applications`, falling back to `osascript ... with
  administrator privileges` when the direct copy is not permitted.

## Known limitations

- `Installer.swift` copies to `~/Applications`, whereas the active install path
  (the `build.sh` helper invoked by `BuildManager`) installs to `/Applications`.
  `Installer` is not currently called from the build flow.
- Only the first `.app` found in the build output is installed; multi-app or
  multi-target projects install just one.
- The helper script runs outside the sandbox and may prompt for administrator
  privileges when writing to `/Applications`.
- No automated tests are present.
- Build configuration is fixed to Release; no scheme/target/configuration
  selection in the UI.
