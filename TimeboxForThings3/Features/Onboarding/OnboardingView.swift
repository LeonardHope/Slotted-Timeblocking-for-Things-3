import SwiftUI

/// Shown when the app can't find the Things 3 database.
struct OnboardingView: View {
    let onGrantAccess: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "clock.badge.checkmark")
                .font(.system(size: 56))
                .foregroundStyle(.blue)

            Text("Welcome to Timebox for Things 3")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)

            Text("To get started, grant access to your Things 3 database.\nYour data is read-only — we never modify your tasks.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            VStack(spacing: 12) {
                Button(action: onGrantAccess) {
                    Label("Select Things 3 Database", systemImage: "folder")
                        .frame(maxWidth: 250)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Skip for now", action: onSkip)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("How to find the database:", systemImage: "questionmark.circle")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.secondary)

                Text("1. Click \"Select Things 3 Database\" above\n2. Navigate to: ~/Library/Group Containers/\n3. Open the folder starting with \"JLMPQHK86H\"\n4. Open \"ThingsData-...\", then \"Things Database.thingsdatabase\"\n5. Select \"main.sqlite\"")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 28)
            }
            .frame(maxWidth: 400, alignment: .leading)

            Spacer()
        }
        .padding(40)
        .frame(minWidth: 500, minHeight: 450)
    }
}
