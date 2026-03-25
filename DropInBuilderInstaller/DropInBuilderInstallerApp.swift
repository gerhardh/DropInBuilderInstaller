//
//  DropInBuilderInstallerApp.swift
//  DropInBuilderInstaller
//
//  Created by Gerhard Heidkamp on 2026-03-25.
//

import SwiftUI

@main
struct DropInBuilderInstallerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 700, minHeight: 420)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        NotificationCenter.default.post(name: .didSelectFolder, object: url)
    }
}

extension Notification.Name {
    static let didSelectFolder = Notification.Name("didSelectFolder")
}
