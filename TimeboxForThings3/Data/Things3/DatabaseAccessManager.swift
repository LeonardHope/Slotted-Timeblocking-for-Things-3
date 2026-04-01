import AppKit
import UniformTypeIdentifiers

/// Manages access to the Things 3 database, handling sandbox restrictions
/// via security-scoped bookmarks on the containing directory.
@MainActor
final class DatabaseAccessManager {
    private static let bookmarkKey = "things3DatabaseDirBookmark"
    private var accessingURL: URL?

    /// Attempt to find or restore access to the Things 3 database.
    /// Returns the path if accessible, nil if user action is needed.
    func resolveAccess() -> String? {
        // 1. Try restoring a saved bookmark
        if let path = restoreBookmark() {
            return path
        }

        // 2. Try the known path directly (works outside sandbox)
        if let path = try? Things3Database.findDatabasePath() {
            return path
        }

        return nil
    }

    /// Present an open panel for the user to grant access to the Things 3 database directory.
    func requestUserAccess() -> String? {
        let panel = NSOpenPanel()
        panel.title = "Select Your Things 3 Database"
        panel.message = "Navigate to the Things 3 database and select the \"main.sqlite\" file."
        panel.prompt = "Grant Access"
        panel.allowedContentTypes = [.data]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.showsHiddenFiles = true
        panel.treatsFilePackagesAsDirectories = true
        panel.directoryURL = suggestedDirectory()

        let validator = OpenPanelValidator()
        panel.delegate = validator

        guard panel.runModal() == .OK, let fileURL = panel.url else {
            return nil
        }

        guard fileURL.lastPathComponent == "main.sqlite" else {
            return nil
        }

        // Bookmark the parent directory (grants access to WAL/SHM files too)
        let dirURL = fileURL.deletingLastPathComponent()
        saveBookmark(for: dirURL)

        return fileURL.path
    }

    // MARK: - Bookmark persistence

    private func saveBookmark(for dirURL: URL) {
        do {
            let bookmark = try dirURL.bookmarkData(
                options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(bookmark, forKey: Self.bookmarkKey)
        } catch {
            // Bookmark creation failed
        }
    }

    private func restoreBookmark() -> String? {
        guard let data = UserDefaults.standard.data(forKey: Self.bookmarkKey) else {
            return nil
        }

        do {
            var isStale = false
            let dirURL = try URL(
                resolvingBookmarkData: data,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            guard dirURL.startAccessingSecurityScopedResource() else {
                return nil
            }
            accessingURL = dirURL

            if isStale {
                saveBookmark(for: dirURL)
            }

            let dbPath = dirURL.appendingPathComponent("main.sqlite").path
            guard FileManager.default.fileExists(atPath: dbPath) else {
                dirURL.stopAccessingSecurityScopedResource()
                accessingURL = nil
                return nil
            }

            return dbPath
        } catch {
            return nil
        }
    }

    /// Clear the saved bookmark.
    func clearBookmark() {
        if let url = accessingURL {
            url.stopAccessingSecurityScopedResource()
            accessingURL = nil
        }
        UserDefaults.standard.removeObject(forKey: Self.bookmarkKey)
    }

    // MARK: - Helpers

    private func suggestedDirectory() -> URL? {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let groupContainer = home.appendingPathComponent(
            "Library/Group Containers/JLMPQHK86H.com.culturedcode.ThingsMac"
        )
        if let contents = try? FileManager.default.contentsOfDirectory(at: groupContainer, includingPropertiesForKeys: nil),
           let thingsDataDir = contents.first(where: { $0.lastPathComponent.hasPrefix("ThingsData-") }) {
            return thingsDataDir.appendingPathComponent("Things Database.thingsdatabase")
        }
        if FileManager.default.fileExists(atPath: groupContainer.path) {
            return groupContainer
        }
        let groupContainers = home.appendingPathComponent("Library/Group Containers")
        if FileManager.default.fileExists(atPath: groupContainers.path) {
            return groupContainers
        }
        return home.appendingPathComponent("Library")
    }
}

/// Only enable Grant Access for main.sqlite files.
private class OpenPanelValidator: NSObject, NSOpenSavePanelDelegate {
    func panel(_ sender: Any, shouldEnable url: URL) -> Bool {
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
            return true
        }
        return url.lastPathComponent == "main.sqlite"
    }
}
