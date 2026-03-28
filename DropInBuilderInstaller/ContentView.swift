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
                TextEditor(text: .constant(logs))
                    .font(.system(.body, design: .monospaced))
                    .padding(4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(6)
            .padding()

            HStack {
                Spacer()
                Button("Clear & Rebuild") {
                    guard let url = selectedURL, !isBuilding else { return }
                    logs = ""
                    buildAndInstall(projectURL: url, clean: true)
                }
                .disabled(selectedURL == nil || isBuilding)

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
        .onAppear {
            if let url = BookmarkManager.restoreBookmark() {
                selectedURL = url
                appendLog("Restored: \(url.path)")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didSelectFolder)) { n in
            if let url = n.object as? URL {
                selectURL(url)
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
                selectURL(url)
            }
        }
    }

    func selectURL(_ url: URL) {
        selectedURL = url
        appendLog("Selected: \(url.path)")
        try? BookmarkManager.saveBookmark(for: url)
    }

    func appendLog(_ line: String) {
        DispatchQueue.main.async {
            logs += (logs.isEmpty ? "" : "\n") + line
        }
    }

    func buildAndInstall(projectURL: URL, clean: Bool = false) {
        appendLog(clean ? "Starting clean build..." : "Starting build...")
        isBuilding = true

        Task {
            let manager = BuildManager()
            let result = await manager.buildProject(at: projectURL, clean: clean) { out in
                appendLog(out)
            }
            await MainActor.run {
                isBuilding = false
            }
            switch result {
            case .success(let appURL):
                appendLog("Build succeeded: \(appURL.path)")
            case .failure(let error):
                appendLog("Build failed: \(error.localizedDescription)")
            }
        }
    }
}


#Preview {
    ContentView()
}
