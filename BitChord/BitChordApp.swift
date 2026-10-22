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
                .onChange(of: settingsManager.settings.lastfmApiKey) { _, _ in
                    updateLastFmService()
                }
                .onChange(of: settingsManager.settings.lastfmSecret) { _, _ in
                    updateLastFmService()
                }
                .onChange(of: settingsManager.settings.lastfmSessionKey) { _, _ in
                    updateLastFmService()
                }
        }
    }

    private func setupApp() {
        Task {
            await AuthManager.shared.initialize()
            await YTMusicRepository.shared.initialize()
        }
        AudioSessionManager.shared.configure()
        updateLastFmService()
    }

    private func updateLastFmService() {
        guard let apiKey = settingsManager.settings.lastfmApiKey,
              let secret = settingsManager.settings.lastfmSecret else {
            playbackManager.setLastFmService(nil)
            return
        }

        let service = LastFMService(
            apiKey: apiKey,
            secret: secret,
            sessionKey: settingsManager.settings.lastfmSessionKey
        )
        playbackManager.setLastFmService(service)
    }
}
