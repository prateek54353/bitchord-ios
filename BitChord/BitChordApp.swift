import SwiftUI

@main
struct BitChordApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var playbackManager = PlaybackManager()
    @StateObject private var libraryManager = LibraryManager()
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var authManager = AuthManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(playbackManager)
                .environmentObject(libraryManager)
                .environmentObject(settingsManager)
                .environmentObject(authManager)
                .onAppear {
                    setupApp()
                }
        }
    }

    private func setupApp() {
        Task {
            await AuthManager.shared.initialize()
            await YTMusicRepository.shared.initialize()
        }
        AudioSessionManager.shared.configure()
    }
}
