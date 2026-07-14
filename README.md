# DropInBuilderInstaller

A sandboxed macOS (Tahoe / macOS 26, SwiftUI + AppKit) app that builds a project
you point it at and installs the resulting app into `/Applications`.

Point it at a folder containing a Swift Package (`Package.swift`), an Xcode
workspace (`.xcworkspace`), or an Xcode project (`.xcodeproj`). The app builds it
in Release and drops the built `.app` into `/Applications` for you to run.

## Features

- Project-type detection: Swift Package Manager, Xcode workspace, Xcode project.
- Incremental "Build & Install" and clean "Clear & Rebuild" actions.
- Live streaming build log (stdout + stderr), deadlock-free.
- Installs the built `.app` to `/Applications`, falling back to administrator
  privileges when a direct copy is not permitted.
- Sandbox-friendly: builds run through a helper script installed into
  `~/Library/Application Scripts/…` via an `NSSavePanel` prompt.
- Remembers the last selected folder across launches with a security-scoped
  bookmark.
- Opens a folder passed to the app via URL / drop.

## Requirements

- macOS 26.4 (Tahoe) or later.
- Xcode command-line tools (`xcodebuild`, `swift`) for building projects.

## Building this app

```bash
xcodebuild -project DropInBuilderInstaller.xcodeproj \
  -scheme DropInBuilderInstaller -configuration Release build
```

- Bundle identifier: `de.dieheidkamps.DropInBuilderInstaller`

## Documentation

- `Docs/HELP.md` — user guide
- `Docs/STATE.md` — components, configuration, limitations
- `Docs/HISTORY.md` — changelog
- `Docs/PLAN.md` — roadmap

## Notes

The build helper runs outside the app sandbox and may prompt for administrator
privileges when installing to `/Applications`. See `Docs/STATE.md` for a known
discrepancy between `Installer.swift` (targets `~/Applications`) and the active
install path (targets `/Applications`).
