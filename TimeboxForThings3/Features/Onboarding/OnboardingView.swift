import AppKit
import SwiftUI

/// Shown when the app can't find the Things 3 database.
struct OnboardingView: View {
    let onGrantAccess: () -> Void

    private static let thingsBundleIDs = [
        "com.culturedcode.ThingsMac",         // Mac App Store / direct
        "com.culturedcode.ThingsMac-setapp",  // Setapp
    ]

    private var thingsInstalled: Bool {
        Self.thingsBundleIDs.contains {
            NSWorkspace.shared.urlForApplication(withBundleIdentifier: $0) != nil
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 40)

                Image(systemName: "clock.badge.checkmark")
                    .font(.system(size: 56))
                    .foregroundStyle(.blue)
                    .accessibilityLabel("Slotted app icon")

                Text("Welcome to Slotted")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)

                if thingsInstalled {
                    grantAccessContent
                } else {
                    thingsMissingContent
                }

                Spacer(minLength: 24)

                Text("Slotted is an independent app and is not affiliated with or endorsed by Cultured Code. Things is a trademark of Cultured Code GmbH & Co. KG.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
                    .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(minWidth: 500, minHeight: 400)
    }

    private var grantAccessContent: some View {
        VStack(spacing: 24) {
            Text("To get started, grant access to your Things 3 database.\nYour data is read-only — we never modify your tasks.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            Button(action: onGrantAccess) {
                Label("Select Things 3 Database", systemImage: "folder")
                    .frame(maxWidth: 250)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityHint("Opens a file picker to select the Things 3 database folder")

            VStack(alignment: .leading, spacing: 6) {
                Label("How to find the database:", systemImage: "questionmark.circle")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)

                VStack(alignment: .leading, spacing: 3) {
                    Text("1. Click the button above")
                    Text("2. Go to ~/Library/Group Containers/")
                    Text("3. Open the \"JLMPQHK86H...\" folder")
                    Text("4. Open \"ThingsData-...\"")
                    Text("5. Select \"Things Database.thingsdatabase\"")
                    Text("6. Click Grant Access")
                }
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(.leading, 28)
            }
            .frame(alignment: .leading)
            .fixedSize(horizontal: true, vertical: false)
        }
    }

    private var thingsMissingContent: some View {
        VStack(spacing: 16) {
            Label("Things 3 doesn't appear to be installed", systemImage: "exclamationmark.triangle")
                .font(.body.weight(.medium))
                .foregroundStyle(.orange)

            Text("Slotted is a time-blocking companion for Things 3 and needs it to show your tasks. Install Things 3, add a task or two, then come back here.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            Link("Get Things 3", destination: URL(string: "https://culturedcode.com/things/")!)
                .font(.body.weight(.medium))

            Text("Already have Things 3 installed somewhere unusual?")
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            Button(action: onGrantAccess) {
                Label("Select Things 3 Database", systemImage: "folder")
                    .frame(maxWidth: 250)
            }
            .controlSize(.large)
            .accessibilityHint("Opens a file picker to select the Things 3 database folder")
        }
    }
}
