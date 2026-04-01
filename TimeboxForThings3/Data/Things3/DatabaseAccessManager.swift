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
        panel.title = "Select Things 3 Database Folder"
        panel.message = "Select the \"Things Database.thingsdatabase\" folder."
        panel.prompt = "Grant Access"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.showsHiddenFiles = true
        panel.treatsFilePackagesAsDirectories = true
        panel.directoryURL = suggestedDirectory()

        guard panel.runModal() == .OK, let dirURL = panel.url else {
            return nil
        }

        // Verify main.sqlite exists in the selected directory
        let dbPath = dirURL.appendingPathComponent("main.sqlite").path
        guard FileManager.default.fileExists(atPath: dbPath) else {
            return nil
        }

        saveBookmark(for: dirURL)
        return dbPath
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

