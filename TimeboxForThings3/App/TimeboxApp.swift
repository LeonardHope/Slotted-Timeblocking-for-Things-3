import SwiftUI

@main
struct TimeboxApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(\.textScale, appState.textScale)
                .preferredColorScheme(appState.preferredColorScheme)
                .frame(minWidth: 800, minHeight: 600)
        }
        .defaultSize(width: 1100, height: 750)
    }
}

// MARK: - Text Scale Environment Key

private struct TextScaleKey: EnvironmentKey {
    static let defaultValue: Double = 1.0
}

extension EnvironmentValues {
    var textScale: Double {
        get { self[TextScaleKey.self] }
        set { self[TextScaleKey.self] = newValue }
    }
}
