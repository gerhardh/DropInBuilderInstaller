//
//  Installer.swift
//  DropInBuilderInstaller
//
//  Created by Gerhard Heidkamp on 2026-03-25.
//

import Foundation

enum InstallerError: Error {
    case destinationUnavailable
    case copyFailed(Error)
}

struct Installer {
    static func installApp(at appURL: URL) throws {
        let fm = FileManager.default
        let homeApps = fm.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
        if !fm.fileExists(atPath: homeApps.path) {
            try fm.createDirectory(at: homeApps, withIntermediateDirectories: true)
        }
        let dest = homeApps.appendingPathComponent(appURL.lastPathComponent)
        if fm.fileExists(atPath: dest.path) {
            try fm.removeItem(at: dest)
        }
        do {
            try fm.copyItem(at: appURL, to: dest)
        } catch {
            throw InstallerError.copyFailed(error)
        }
    }
}

