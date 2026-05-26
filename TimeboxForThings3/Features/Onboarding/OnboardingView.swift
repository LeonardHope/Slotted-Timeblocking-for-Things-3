import SwiftUI

/// Shown when the app can't find the Things 3 database.
struct OnboardingView: View {
    let onGrantAccess: () -> Void

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

                Spacer(minLength: 40)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}
