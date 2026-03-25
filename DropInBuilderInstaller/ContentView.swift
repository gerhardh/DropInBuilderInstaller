//
//  ContentView.swift
//  DropInBuilderInstaller
//
//  Created by Gerhard Heidkamp on 2026-03-25.
//

import SwiftUI

struct ContentView: View {
    @State private var logs: String = ""
    @State private var selectedURL: URL?
    @State private var isBuilding = false

    var body: some View {
        VStack {
            HStack {
                Button("Select Folder") { selectFolder() }
                Spacer()
                if let url = selectedURL {
                    Text(url.lastPathComponent)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("No folder selected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }.padding()

            Divider()

            ScrollView {
                Text(logs)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(6)
            .padding()

            HStack {
                Spacer()
                Button(action: {
                    guard let url = selectedURL, !isBuilding else { return }
                    buildAndInstall(projectURL: url)
                }) {
                    HStack {
                        if isBuilding {
                            ProgressView()
                        }
                        Text(isBuilding ? "Building..." : "Build & Install")
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedURL == nil || isBuilding)
            }.padding()
        }
        .onReceive(NotificationCenter.default.publisher(for: .didSelectFolder)) { n in
            if let url = n.object as? URL {
                selectedURL = url
                appendLog("Selected: \(url.path)")
            }
        }
    }

    func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.begin { resp in
            if resp == .OK, let url = panel.url {
                selectedURL = url
                appendLog("Selected: \(url.path)")
            }
        }
    }

    func appendLog(_ line: String) {
        DispatchQueue.main.async {
            logs += (logs.isEmpty ? "" : "\n") + line
        }
    }

    func buildAndInstall(projectURL: URL) {
        appendLog("Starting build...")
        isBuilding = true

        Task {
            let manager = BuildManager()
            let result = await manager.buildProject(at: projectURL) { out in
                appendLog(out)
            }
            await MainActor.run {
                isBuilding = false
            }
            switch result {
            case .success(let appURL):
                appendLog("Build succeeded: \(appURL.path)")
                do {
                    try Installer.installApp(at: appURL)
                    appendLog("Installed to ~/Applications")
                } catch {
                    appendLog("Install failed: \(error.localizedDescription)")
                }
            case .failure(let error):
                appendLog("Build failed: \(error.localizedDescription)")
            }
        }
    }
}


#Preview {
    ContentView()
}
