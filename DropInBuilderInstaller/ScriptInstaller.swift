//
//  ScriptInstaller.swift
//  DropInBuilderInstaller
//
//  Created by Gerhard Heidkamp on 2026-03-25.
//

import AppKit
import Foundation

struct ScriptInstaller {
    static let scriptName = "build.sh"

    private static var realHomeDirectory: URL {
        if let pw = getpwuid(getuid()), let home = pw.pointee.pw_dir {
            return URL(fileURLWithPath: String(cString: home))
        }
        return FileManager.default.homeDirectoryForCurrentUser
    }

    static var scriptsDirectoryURL: URL {
        realHomeDirectory
            .appendingPathComponent("Library/Application Scripts/de.dieheidkamps.DropInBuilderInstaller")
    }

    static var scriptURL: URL {
        scriptsDirectoryURL.appendingPathComponent(scriptName)
    }

    static let scriptContent = """
#!/bin/bash
set -euo pipefail

ACTION="$1"
PROJECT_PATH="$2"
ARG3="${3:-}"
BUILD_MODE="${4:-incremental}"

install_app() {
    local APP_PATH="$1"
    local DEST_DIR="/Applications"
    local APP_NAME
    APP_NAME=$(basename "$APP_PATH")

    # Try direct copy first (works if user has write access to /Applications)
    rm -rf "$DEST_DIR/$APP_NAME" 2>/dev/null
    if cp -R "$APP_PATH" "$DEST_DIR/" 2>/dev/null; then
        if [ -d "$DEST_DIR/$APP_NAME" ]; then
            echo "INSTALLED:$DEST_DIR/$APP_NAME"
            return
        fi
    fi

    # Fall back to admin privileges via osascript
    local RESULT
    RESULT=$(osascript <<ASCRIPT
do shell script "rm -rf '$DEST_DIR/$APP_NAME' && cp -R '$APP_PATH' '$DEST_DIR/'" with administrator privileges
ASCRIPT
    ) 2>&1
    if [ -d "$DEST_DIR/$APP_NAME" ]; then
        echo "INSTALLED:$DEST_DIR/$APP_NAME"
        return
    fi

    echo "INSTALL_FAILED:Could not copy $APP_NAME to $DEST_DIR — $RESULT"
}

case "$ACTION" in
    swiftpm)
        cd "$PROJECT_PATH"
        if [ "$BUILD_MODE" = "clean" ]; then
            swift package clean 2>&1
        fi
        swift build -c release 2>&1
        EXIT_CODE=$?
        if [ $EXIT_CODE -eq 0 ]; then
            APP=$(find "$PROJECT_PATH/.build" -name "*.app" -type d -print -quit 2>/dev/null)
            if [ -n "$APP" ]; then
                echo "BUILD_APP_PATH:$APP"
                install_app "$APP"
            fi
        fi
        exit $EXIT_CODE
        ;;
    xcode-workspace)
        BUILD_DIR="$PROJECT_PATH/build"
        if [ "$BUILD_MODE" = "clean" ]; then
            xcodebuild -workspace "$ARG3" -configuration Release "BUILD_DIR=$BUILD_DIR" clean 2>&1
        fi
        xcodebuild -workspace "$ARG3" -configuration Release "BUILD_DIR=$BUILD_DIR" 2>&1
        EXIT_CODE=$?
        if [ $EXIT_CODE -eq 0 ]; then
            APP=$(find "$BUILD_DIR" -name "*.app" -type d -print -quit 2>/dev/null)
            if [ -n "$APP" ]; then
                echo "BUILD_APP_PATH:$APP"
                install_app "$APP"
            fi
        fi
        exit $EXIT_CODE
        ;;
    xcode-project)
        BUILD_DIR="$PROJECT_PATH/build"
        if [ "$BUILD_MODE" = "clean" ]; then
            xcodebuild -project "$ARG3" -configuration Release "BUILD_DIR=$BUILD_DIR" clean 2>&1
        fi
        xcodebuild -project "$ARG3" -configuration Release "BUILD_DIR=$BUILD_DIR" 2>&1
        EXIT_CODE=$?
        if [ $EXIT_CODE -eq 0 ]; then
            APP=$(find "$BUILD_DIR" -name "*.app" -type d -print -quit 2>/dev/null)
            if [ -n "$APP" ]; then
                echo "BUILD_APP_PATH:$APP"
                install_app "$APP"
            fi
        fi
        exit $EXIT_CODE
        ;;
    *)
        echo "Unknown action: $ACTION" >&2
        exit 1
        ;;
esac
"""

    /// Prompt the user with a Save panel to install the build script.
    /// The NSSavePanel grants sandbox write access to the chosen location.
    @MainActor
    static func installScriptWithPrompt() async -> Bool {
        let panel = NSSavePanel()
        panel.title = "Install Build Helper Script"
        panel.message = "DropInBuilderInstaller needs to install a helper script to run builds outside the sandbox. Please confirm saving to this location."
        panel.directoryURL = scriptsDirectoryURL
        panel.nameFieldStringValue = scriptName
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false

        let response = await panel.begin()
        guard response == .OK, let url = panel.url else { return false }

        guard let data = scriptContent.data(using: .utf8) else { return false }

        do {
            try data.write(to: url)
            // Make executable
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
            return true
        } catch {
            return false
        }
    }

    static func isInstalled() -> Bool {
        guard FileManager.default.isExecutableFile(atPath: scriptURL.path) else { return false }
        // Check if the installed script matches the current version
        guard let installed = try? String(contentsOf: scriptURL, encoding: .utf8) else { return false }
        return installed == scriptContent
    }
}
