import Foundation
import Combine

/// Settings manager for app preferences
@MainActor
class SettingsManager: ObservableObject {
    @Published var settings: AppSettings

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.settings = Self.loadSettings(from: userDefaults)
    }

    // MARK: - Playback Settings

    func setAudioQualityWiFi(_ quality: AudioQuality) {
        settings.audioQualityWiFi = quality
        saveSettings()
    }

    func setAudioQualityMobile(_ quality: AudioQuality) {
        settings.audioQualityMobile = quality
        saveSettings()
    }

    func setCrossfadeDuration(_ duration: TimeInterval) {
        settings.crossfadeDuration = duration
        saveSettings()
    }

    func setPlaybackSpeed(_ speed: Double) {
        settings.playbackSpeed = speed
        saveSettings()
    }

    func setSkipSilence(_ enabled: Bool) {
        settings.skipSilence = enabled
        saveSettings()
    }

    func setLoudnessNormalization(_ enabled: Bool) {
        settings.loudnessNormalization = enabled
        saveSettings()
    }

    func setGaplessPlayback(_ enabled: Bool) {
        settings.gaplessPlayback = enabled
        saveSettings()
    }

    func setSleepTimerDuration(_ duration: TimeInterval?) {
        settings.sleepTimerDuration = duration
        saveSettings()
    }

    func setSleepTimerStopAfterTrack(_ enabled: Bool) {
        settings.sleepTimerStopAfterTrack = enabled
        saveSettings()
    }

    // MARK: - Appearance Settings

    func setThemeMode(_ mode: ThemeMode) {
        settings.themeMode = mode
        saveSettings()
    }

    func setArtworkDrivenTheming(_ enabled: Bool) {
        settings.artworkDrivenTheming = enabled
        saveSettings()
    }

    func setAppLanguage(_ language: String?) {
        settings.appLanguage = language
        saveSettings()
    }

    // MARK: - Library Settings

    func setHomeRecentsViewType(_ type: LibraryViewType) {
        settings.homeRecentsViewType = type
        saveSettings()
    }

    func setLibrarySort(_ sort: LibrarySort) {
        settings.librarySort = sort
        saveSettings()
    }

    func setSwipeToPlayNext(_ enabled: Bool) {
        settings.swipeToPlayNext = enabled
        saveSettings()
    }

    func setPinnedPlaylists(_ playlistIds: [String]) {
        settings.pinnedPlaylists = playlistIds
        saveSettings()
    }

    // MARK: - Integration Settings

    func setLastfmSessionKey(_ key: String?) {
        settings.lastfmSessionKey = key
        saveSettings()
    }

    func setLastfmApiKey(_ key: String?) {
        settings.lastfmApiKey = key
        saveSettings()
    }

    func setLastfmSecret(_ secret: String?) {
        settings.lastfmSecret = secret
        saveSettings()
    }

    func setLastfmEndpoint(_ endpoint: String) {
        settings.lastfmEndpoint = endpoint
        saveSettings()
    }

    func setLastfmScrobbleEnabled(_ enabled: Bool) {
        settings.lastfmScrobbleEnabled = enabled
        saveSettings()
    }

    func setListenBrainzToken(_ token: String?) {
        settings.listenBrainzToken = token
        saveSettings()
    }

    func setListenBrainzEnabled(_ enabled: Bool) {
        settings.listenBrainzEnabled = enabled
        saveSettings()
    }

    func setDiscordRichPresenceEnabled(_ enabled: Bool) {
        settings.discordRichPresenceEnabled = enabled
        saveSettings()
    }

    // MARK: - Source Settings

    func setUseModuleSources(_ enabled: Bool) {
        settings.useModuleSources = enabled
        saveSettings()
    }

    func setPreferredSourceId(_ sourceId: String?) {
        settings.preferredSourceId = sourceId
        saveSettings()
    }

    // MARK: - Party Settings

    func setPartyServerUrl(_ url: String) {
        settings.partyServerUrl = url
        saveSettings()
    }

    // MARK: - Persistence

    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            userDefaults.set(encoded, forKey: "appSettings")
        }
    }

    private static func loadSettings(from userDefaults: UserDefaults) -> AppSettings {
        if let data = userDefaults.data(forKey: "appSettings"),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            return decoded
        }
        return AppSettings()
    }
}
