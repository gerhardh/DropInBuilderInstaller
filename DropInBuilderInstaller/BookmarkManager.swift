//
//  BookmarkManager.swift
//  DropInBuilderInstaller
//
//  Created by Gerhard Heidkamp on 2026-03-25.
//

import Foundation

struct BookmarkManager {
    private static let bookmarkKey = "selectedFolderBookmark"

    static func saveBookmark(for url: URL) throws {
        let data = try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        UserDefaults.standard.set(data, forKey: bookmarkKey)
    }

    static func restoreBookmark() -> URL? {
        guard let data = UserDefaults.standard.data(forKey: bookmarkKey) else { return nil }
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: data,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else { return nil }

        if isStale {
            // Re-save to refresh the bookmark
            try? saveBookmark(for: url)
        }

        guard url.startAccessingSecurityScopedResource() else { return nil }
        return url
    }
}
