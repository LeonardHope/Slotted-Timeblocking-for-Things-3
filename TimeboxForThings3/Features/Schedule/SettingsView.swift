import SwiftUI

/// Settings popover for user preferences.
struct SettingsView: View {
    @Environment(AppState.self) private var appState

    private let hourOptions = Array(0...23)

    private let appearanceOptions: [(String, AppearanceMode)] = [
        ("Auto", .auto),
        ("Light", .light),
        ("Dark", .dark),
    ]

    var body: some View {
        @Bindable var state = appState

        Form {
            Section("Schedule Hours") {
                Picker("Start", selection: $state.startHour) {
                    ForEach(hourOptions, id: \.self) { hour in
                        Text(formatHour(hour)).tag(hour)
                    }
                }

                Picker("End", selection: $state.endHour) {
                    ForEach(hourOptions, id: \.self) { hour in
                        Text(formatHour(hour)).tag(hour)
                    }
                }
            }

            Section("Text Size") {
                HStack(spacing: 8) {
                    Text("A")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Slider(value: $state.textScale, in: 0.8...1.4, step: 0.05)
                    Text("A")
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                }
            }

            Section("Task List") {
                Toggle("Hide empty categories", isOn: $state.hideEmptyCategories)
            }

            Section("Appearance") {
                Picker("Theme", selection: $state.appearanceMode) {
                    ForEach(appearanceOptions, id: \.1) { label, mode in
                        Text(label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .formStyle(.grouped)
        .frame(width: 260)
        .padding(.vertical, 8)
    }

    private func formatHour(_ hour: Int) -> String {
        if hour == 0 { return "12 AM" }
        if hour < 12 { return "\(hour) AM" }
        if hour == 12 { return "12 PM" }
        return "\(hour - 12) PM"
    }
}
