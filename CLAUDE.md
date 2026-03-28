# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

<!-- Replace this section with a brief description of your project:
- What it does
- Tech stack (e.g., SwiftUI, SwiftData, Vapor, etc.)
- Platforms (macOS, iOS, iPadOS, web)
- Build targets
-->

## Build Commands

<!-- Add your project-specific build commands here, e.g.:
```bash
xcodebuild -project MyApp.xcodeproj -scheme MyApp build
```
-->

## Rules

### Core Rules (always active)

- All apps are sandboxed. Never disable the sandbox (`com.apple.security.app-sandbox` must stay `true`).
- Always use security-scoped bookmarks to persist user-selected file/folder access across launches. Never save plain URLs to UserDefaults for this purpose.
- Security-scoped bookmarks require the `com.apple.security.files.bookmarks.app-scope` entitlement in the app's entitlements file.
- On relaunch, resolve the bookmark and call `startAccessingSecurityScopedResource()` before accessing the directory.
- Use `NSOpenPanel` to get user permission for folder access, then store bookmarks.
- After building, always install to `/Applications` before asking the user to test.
- Always kill the running app, clean build, and reinstall before testing.
- Use `feature/` prefix for feature branches (not `features/`).
- Always commit with descriptive messages.
- Functionality first, polish later. UI redesign happens when features are nearly complete.

### Optional Rules

Enable a rule by removing the `<!--` and `-->` comment markers around it.

<!-- ENABLE if this project must always be built for physical devices (e.g., relies on hardware sensors):
- Always build for real devices, never simulators.
-->

<!-- ENABLE if this is a macOS app designed for large displays (Studio Display, 5K screens):
- Default window sizes should be generous (1200x800 or larger).
- Use resizable windows instead of fixed-size modal sheets for forms.
- Text fields for paths/URLs should expand to fill available width.
-->

<!-- ENABLE if this project includes a server component (e.g., Vapor) that needs to bind network ports:
- Server app may need reduced sandbox for network binding.
-->

<!-- ENABLE if this project uses SwiftUI Table with many columns:
- SwiftUI Table column limit is 10. Use `Group` within `@TableColumnBuilder` to exceed it.
- Extract complex column content closures into separate small views to avoid Swift type-checker timeouts.
-->

<!-- ENABLE if this project uses a multi-package architecture with shared code:
- Put shared models in the shared Core package.
- Put shared UI components in the shared UI package.
- Platform-specific code stays in respective app targets.
-->

<!-- ENABLE if this project uses offline-first sync with a server:
- Use offline queue with timestamps for sync.
- Use last-write-wins conflict resolution.
- Photos are additive (never auto-delete during sync).
-->
