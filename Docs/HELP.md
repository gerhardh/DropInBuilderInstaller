# HELP

User-facing guide. Verified against the current source.

## What it does

DropInBuilderInstaller builds a macOS project you point it at and installs the
resulting app so you can run it. It supports Swift Package Manager packages,
Xcode workspaces, and Xcode projects.

## First run: installing the build helper

Builds run outside the app sandbox via a small helper script. The first time you
build, the app shows a Save panel titled "Install Build Helper Script". Confirm
the suggested location to install `build.sh` into
`~/Library/Application Scripts/de.dieheidkamps.DropInBuilderInstaller`. The app
reinstalls the script automatically if it is missing or out of date.

## Selecting a project

- Click "Select Folder" and choose the folder that contains your project.
- The folder must contain one of: `Package.swift`, an `.xcworkspace`, or an
  `.xcodeproj`.
- You can also open the app with a folder (for example via the "open with"
  mechanism); the folder is selected automatically.
- Your selection is remembered between launches via a security-scoped bookmark
  and restored on the next launch.

## Building and installing

- "Build & Install" (the default action, Return) runs an incremental Release
  build and, on success, copies the built `.app` to `/Applications`.
- "Clear & Rebuild" clears the log and runs a clean Release build first.
- Progress and output stream into the log area while the build runs. The buttons
  are disabled until a folder is selected and while a build is in progress.

## Installing to /Applications

The helper first tries a direct copy to `/Applications`. If that is not
permitted, it falls back to requesting administrator privileges, so you may be
prompted for your password. On success the log shows the installed location; on
failure it shows the reason.

## Troubleshooting

- "No Xcode project/workspace or Package.swift found." — the selected folder does
  not contain a recognized project; pick the folder that directly holds one of
  the supported files.
- "Build script is not installed. Please restart the app." — confirm the Save
  panel to install the helper, then build again.
- "Built .app not found." — the build succeeded but no `.app` was produced (for
  example a library-only package).
- "Build failed: ..." — read the streamed log for the underlying `xcodebuild` or
  `swift build` error.
