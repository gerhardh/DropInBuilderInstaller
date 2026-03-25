//
//  BuildManager.swift
//  DropInBuilderInstaller
//
//  Created by Gerhard Heidkamp on 2026-03-25.
//

import Foundation

actor BuildManager {
    enum BuildError: Error, LocalizedError {
        case projectNotFound
        case buildFailed(String)
        case appNotFound

        var errorDescription: String? {
            switch self {
            case .projectNotFound: return "No Xcode project/workspace or Package.swift found."
            case .buildFailed(let msg): return "Build failed: \(msg)"
            case .appNotFound: return "Built .app not found."
            }
        }
    }

    // Progress callback: append output lines
    func buildProject(at url: URL, output: @escaping (String) -> Void) async -> Result<URL, Error> {
        // Detect SwiftPM
        if FileManager.default.fileExists(atPath: url.appendingPathComponent("Package.swift").path) {
            return await buildSwiftPM(at: url, output: output)
        }

        // Xcode workspace or project
        if let xcworkspace = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            .first(where: { $0.pathExtension == "xcworkspace" }) {
            return await buildXcode(at: url, workspace: xcworkspace, output: output)
        }
        if let xcodeproj = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            .first(where: { $0.pathExtension == "xcodeproj" }) {
            return await buildXcode(at: url, project: xcodeproj, output: output)
        }

        return .failure(BuildError.projectNotFound)
    }

    func buildSwiftPM(at url: URL, output: @escaping (String) -> Void) async -> Result<URL, Error> {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
        process.arguments = ["build", "-c", "release"]
        process.currentDirectoryURL = url

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
        } catch {
            return .failure(error)
        }

        let handle = pipe.fileHandleForReading
        Task { await streamOutput(handle: handle, output: output) }

        process.waitUntilExit()
        if process.terminationStatus != 0 {
            return .failure(BuildError.buildFailed("swift build failed with code \(process.terminationStatus)"))
        }

        let productsDir = url.appendingPathComponent(".build/release")
        if let app = try? FileManager.default.contentsOfDirectory(at: productsDir, includingPropertiesForKeys: nil)
            .first(where: { $0.pathExtension == "app" }) {
            return .success(app)
        }

        // Also check `.build/*/release` (newer SwiftPM layouts)
        if let enumerated = try? FileManager.default.contentsOfDirectory(at: url.appendingPathComponent(".build"), includingPropertiesForKeys: nil) {
            for dir in enumerated {
                let candidate = dir.appendingPathComponent("release")
                if FileManager.default.fileExists(atPath: candidate.path) {
                    if let app = try? FileManager.default.contentsOfDirectory(at: candidate, includingPropertiesForKeys: nil)
                        .first(where: { $0.pathExtension == "app" }) {
                        return .success(app)
                    }
                }
            }
        }

        return .failure(BuildError.appNotFound)
    }

    func buildXcode(at url: URL, workspace: URL? = nil, project: URL? = nil, output: @escaping (String) -> Void) async -> Result<URL, Error> {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcodebuild")
        var args: [String] = []
        if let ws = workspace {
            args += ["-workspace", ws.path]
            // Attempt to auto-detect schemes is intentionally omitted for brevity.
        } else if let proj = project {
            args += ["-project", proj.path]
        }
        // Use a BUILD_DIR inside the project folder
        let buildDir = url.appendingPathComponent("build")
        args += ["-configuration", "Release", "BUILD_DIR=\(buildDir.path)"]
        process.arguments = args
        process.currentDirectoryURL = url

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
        } catch {
            return .failure(error)
        }

        let handle = pipe.fileHandleForReading
        Task { await streamOutput(handle: handle, output: output) }

        process.waitUntilExit()
        if process.terminationStatus != 0 {
            return .failure(BuildError.buildFailed("xcodebuild failed with code \(process.terminationStatus)"))
        }

        // Look for .app in build/Release or build/Release/<SDK>
        let candidates = [
            buildDir.appendingPathComponent("Release"),
            buildDir.appendingPathComponent("Release").appendingPathComponent("macosx")
        ]
        for candidate in candidates {
            if FileManager.default.fileExists(atPath: candidate.path) {
                if let app = try? FileManager.default.contentsOfDirectory(at: candidate, includingPropertiesForKeys: nil)
                    .first(where: { $0.pathExtension == "app" }) {
                    return .success(app)
                }
            }
        }

        // Fallback: search build directory recursively for .app
        if let enumerator = FileManager.default.enumerator(at: buildDir, includingPropertiesForKeys: nil),
           let allObjects = enumerator.allObjects as? [URL],
           let app = allObjects.first(where: { $0.pathExtension == "app" }) {
            return .success(app)
        }

        return .failure(BuildError.appNotFound)
    }

    private func streamOutput(handle: FileHandle, output: @escaping (String) -> Void) async {
        var buffer = Data()
        do {
            for try await byte in handle.bytes {
                if byte == 0x0a {
                    if let line = String(data: buffer, encoding: .utf8) {
                        output(line)
                    }
                    buffer.removeAll()
                } else {
                    buffer.append(byte)
                }
            }
        } catch {
            // Stream ended or read error — flush what we have
        }
        // Flush remaining data
        if !buffer.isEmpty, let line = String(data: buffer, encoding: .utf8) {
            output(line)
        }
    }
}

