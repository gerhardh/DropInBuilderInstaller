//
//  BuildManager.swift
//  DropInBuilderInstaller
//
//  Created by Gerhard Heidkamp on 2026-03-25.
//

import Foundation
import os

actor BuildManager {
    enum BuildError: Error, LocalizedError {
        case projectNotFound
        case buildFailed(String)
        case appNotFound
        case scriptNotInstalled

        var errorDescription: String? {
            switch self {
            case .projectNotFound: return "No Xcode project/workspace or Package.swift found."
            case .buildFailed(let msg): return "Build failed: \(msg)"
            case .appNotFound: return "Built .app not found."
            case .scriptNotInstalled: return "Build script is not installed. Please restart the app."
            }
        }
    }

    func buildProject(at url: URL, clean: Bool = false, output: @escaping @Sendable (String) -> Void) async -> Result<URL, Error> {
        // Ensure script is installed
        if !ScriptInstaller.isInstalled() {
            let installed = await ScriptInstaller.installScriptWithPrompt()
            if !installed {
                return .failure(BuildError.scriptNotInstalled)
            }
            output("Build script installed.")
        }

        // Detect project type
        let fm = FileManager.default

        if fm.fileExists(atPath: url.appendingPathComponent("Package.swift").path) {
            return await runBuildScript(action: "swiftpm", projectPath: url.path, arg3: nil, clean: clean, output: output)
        }

        if let xcworkspace = try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            .first(where: { $0.pathExtension == "xcworkspace" }) {
            return await runBuildScript(action: "xcode-workspace", projectPath: url.path, arg3: xcworkspace.path, clean: clean, output: output)
        }

        if let xcodeproj = try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            .first(where: { $0.pathExtension == "xcodeproj" }) {
            return await runBuildScript(action: "xcode-project", projectPath: url.path, arg3: xcodeproj.path, clean: clean, output: output)
        }

        return .failure(BuildError.projectNotFound)
    }

    private func runBuildScript(action: String, projectPath: String, arg3: String?, clean: Bool, output: @escaping @Sendable (String) -> Void) async -> Result<URL, Error> {
        let scriptURL = ScriptInstaller.scriptURL

        let task: NSUserUnixTask
        do {
            task = try NSUserUnixTask(url: scriptURL)
        } catch {
            return .failure(error)
        }

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe.fileHandleForWriting
        task.standardError = errorPipe.fileHandleForWriting

        var arguments = [action, projectPath]
        if let arg3 = arg3 {
            arguments.append(arg3)
        }
        arguments.append(clean ? "clean" : "incremental")

        // Collect all output for parsing the app path
        let allOutput = OSAllocatedUnfairLock(initialState: "")

        // Use readabilityHandler for fast, chunk-based reading (avoids pipe buffer deadlock)
        let outputDone = DispatchSemaphore(value: 0)
        let errorDone = DispatchSemaphore(value: 0)

        var outputBuffer = Data()
        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if data.isEmpty {
                // EOF — flush remaining buffer
                if !outputBuffer.isEmpty, let line = String(data: outputBuffer, encoding: .utf8) {
                    for l in line.components(separatedBy: "\n") where !l.isEmpty {
                        if l.hasPrefix("INSTALLED:") {
                            let path = String(l.dropFirst("INSTALLED:".count))
                            output("Installed to \(path)")
                        } else if l.hasPrefix("INSTALL_FAILED:") {
                            let reason = String(l.dropFirst("INSTALL_FAILED:".count))
                            output("Install failed: \(reason)")
                        } else if !l.hasPrefix("BUILD_APP_PATH:") {
                            output(l)
                        }
                        allOutput.withLock { $0 += l + "\n" }
                    }
                }
                handle.readabilityHandler = nil
                outputDone.signal()
                return
            }
            outputBuffer.append(data)
            // Process complete lines
            while let newlineRange = outputBuffer.range(of: Data([0x0a])) {
                let lineData = outputBuffer.subdata(in: outputBuffer.startIndex..<newlineRange.lowerBound)
                outputBuffer.removeSubrange(outputBuffer.startIndex...newlineRange.lowerBound)
                if let line = String(data: lineData, encoding: .utf8) {
                    if line.hasPrefix("INSTALLED:") {
                            output("Installed to ~/Applications")
                        } else if !line.hasPrefix("BUILD_APP_PATH:") {
                            output(line)
                        }
                    allOutput.withLock { $0 += line + "\n" }
                }
            }
        }

        var errorBuffer = Data()
        errorPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if data.isEmpty {
                if !errorBuffer.isEmpty, let line = String(data: errorBuffer, encoding: .utf8) {
                    for l in line.components(separatedBy: "\n") where !l.isEmpty {
                        output(l)
                    }
                }
                handle.readabilityHandler = nil
                errorDone.signal()
                return
            }
            errorBuffer.append(data)
            while let newlineRange = errorBuffer.range(of: Data([0x0a])) {
                let lineData = errorBuffer.subdata(in: errorBuffer.startIndex..<newlineRange.lowerBound)
                errorBuffer.removeSubrange(errorBuffer.startIndex...newlineRange.lowerBound)
                if let line = String(data: lineData, encoding: .utf8) {
                    output(line)
                }
            }
        }

        // Execute the script
        let exitError: Error? = await withCheckedContinuation { continuation in
            task.execute(withArguments: arguments) { error in
                outputPipe.fileHandleForWriting.closeFile()
                errorPipe.fileHandleForWriting.closeFile()
                continuation.resume(returning: error)
            }
        }

        // Wait for readers to drain
        outputDone.wait()
        errorDone.wait()

        if let error = exitError {
            return .failure(BuildError.buildFailed(error.localizedDescription))
        }

        // Parse output for the app path marker
        let collected = allOutput.withLock { $0 }
        for line in collected.components(separatedBy: "\n").reversed() {
            if line.hasPrefix("BUILD_APP_PATH:") {
                let appPath = String(line.dropFirst("BUILD_APP_PATH:".count))
                return .success(URL(fileURLWithPath: appPath))
            }
        }

        return .failure(BuildError.appNotFound)
    }
}
