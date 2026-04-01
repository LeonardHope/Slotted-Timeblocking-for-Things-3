import AppKit
import UniformTypeIdentifiers

/// Manages access to the Things 3 database, handling sandbox restrictions
/// via security-scoped bookmarks.
@MainActor
final class DatabaseAccessManager {
    private static let bookmarkKey = "things3DatabaseBookmark"

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

    /// Present an open panel for the user to grant access to the Things 3 database.
    /// Returns the path if the user selected a valid database.
    func requestUserAccess() -> String? {
        let panel = NSOpenPanel()
        panel.title = "Select Your Things 3 Database"
        panel.message = "Navigate to the Things 3 database folder and select \"main.sqlite\".\n\nTypical location: ~/Library/Group Containers/JLMPQHK86H.com.culturedcode.ThingsMac/"
        panel.prompt = "Grant Access"
        panel.allowedContentTypes = [.data]  // Allow all files — we validate after selection
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.showsHiddenFiles = true
        panel.treatsFilePackagesAsDirectories = true
        panel.directoryURL = suggestedDirectory()

        let validator = OpenPanelValidator()
        panel.delegate = validator

        guard panel.runModal() == .OK, let url = panel.url else {
            return nil
        }

        // Save a security-scoped bookmark for future access
        saveBookmark(for: url)

        return url.path
    }

    // MARK: - Bookmark persistence

    private func saveBookmark(for url: URL) {
        do {
            let bookmark = try url.bookmarkData(
                options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(bookmark, forKey: Self.bookmarkKey)
        } catch {
            // Bookmark creation failed — access will work for this session
            // but user will need to re-grant on next launch
        }
    }

    private func restoreBookmark() -> String? {
        guard let data = UserDefaults.standard.data(forKey: Self.bookmarkKey) else {
            return nil
        }

        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: data,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            guard url.startAccessingSecurityScopedResource() else {
                return nil
            }

            // If the bookmark is stale, re-save it
            if isStale {
                saveBookmark(for: url)
            }

            // Verify the file still exists
            guard FileManager.default.fileExists(atPath: url.path) else {
                url.stopAccessingSecurityScopedResource()
                return nil
            }

            return url.path
        } catch {
            return nil
        }
    }

    /// Clear the saved bookmark (e.g., if the database moved).
    func clearBookmark() {
        UserDefaults.standard.removeObject(forKey: Self.bookmarkKey)
    }

    // MARK: - Helpers

    private func suggestedDirectory() -> URL? {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let groupContainer = home.appendingPathComponent(
            "Library/Group Containers/JLMPQHK86H.com.culturedcode.ThingsMac"
        )
        // Try to open directly at the database folder
        if let contents = try? FileManager.default.contentsOfDirectory(at: groupContainer, includingPropertiesForKeys: nil),
           let thingsDataDir = contents.first(where: { $0.lastPathComponent.hasPrefix("ThingsData-") }) {
            return thingsDataDir
                .appendingPathComponent("Things Database.thingsdatabase")
        }
        // Fall back to the group container
        if FileManager.default.fileExists(atPath: groupContainer.path) {
            return groupContainer
        }
        // Fall back to Group Containers (sandbox may block above)
        let groupContainers = home.appendingPathComponent("Library/Group Containers")
        if FileManager.default.fileExists(atPath: groupContainers.path) {
            return groupContainers
        }
        return home.appendingPathComponent("Library")
    }
}

/// Validates that the selected file is main.sqlite before enabling Grant Access.
private class OpenPanelValidator: NSObject, NSOpenSavePanelDelegate {
    func panel(_ sender: Any, shouldEnable url: URL) -> Bool {
        // Enable directories for navigation
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
            return true
        }
        // Only enable main.sqlite files
        return url.lastPathComponent == "main.sqlite"
    }
}
