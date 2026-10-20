import Foundation

/// App settings stored in UserDefaults
struct AppSettings: Codable {
    // Playback settings
    var audioQualityWiFi: AudioQuality
    var audioQualityMobile: AudioQuality
    var crossfadeDuration: TimeInterval
    var playbackSpeed: Double
    var skipSilence: Bool
    var loudnessNormalization: Bool
    var gaplessPlayback: Bool
    var sleepTimerDuration: TimeInterval?
    var sleepTimerStopAfterTrack: Bool

    // Appearance settings
    var themeMode: ThemeMode
    var artworkDrivenTheming: Bool
    var appLanguage: String?

    // Library settings
    var homeRecentsViewType: LibraryViewType
    var librarySort: LibrarySort
    var swipeToPlayNext: Bool
    var pinnedPlaylists: [String]

    // Integration settings
    var lastfmSessionKey: String?
    var lastfmApiKey: String?
    var lastfmSecret: String?
    var lastfmEndpoint: String
    var lastfmScrobbleEnabled: Bool

    var listenBrainzToken: String?
    var listenBrainzEnabled: Bool

    var discordRichPresenceEnabled: Bool

    // Source settings
    var useModuleSources: Bool
    var preferredSourceId: String?

    // Party settings
    var partyServerUrl: String

    init() {
        // Playback defaults
        self.audioQualityWiFi = .high
        self.audioQualityMobile = .medium
        self.crossfadeDuration = 3.0
        self.playbackSpeed = 1.0
        self.skipSilence = false
        self.loudnessNormalization = true
        self.gaplessPlayback = true
        self.sleepTimerDuration = nil
        self.sleepTimerStopAfterTrack = false

        // Appearance defaults
        self.themeMode = .system
        self.artworkDrivenTheming = true
        self.appLanguage = nil

        // Library defaults
        self.homeRecentsViewType = .list
        self.librarySort = .recent
        self.swipeToPlayNext = false
        self.pinnedPlaylists = []

        // Integration defaults
        self.lastfmSessionKey = nil
        self.lastfmApiKey = nil
        self.lastfmSecret = nil
        self.lastfmEndpoint = "https://ws.audioscrobbler.com/2.0/"
        self.lastfmScrobbleEnabled = false

        self.listenBrainzToken = nil
        self.listenBrainzEnabled = false

        self.discordRichPresenceEnabled = false

        // Source defaults
        self.useModuleSources = false
        self.preferredSourceId = nil

        // Party defaults
        self.partyServerUrl = "https://bitchord-listen-together.onrender.com"
    }
}

/// Audio quality options
enum AudioQuality: String, Codable, CaseIterable {
    case auto = "AUTO"
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
    case lossless = "LOSSLESS"
    case hiRes = "HI_RES"

    var displayName: String {
        switch self {
        case .auto: return "Auto"
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .lossless: return "Lossless"
        case .hiRes: return "Hi-Res"
        }
    }
}

/// Theme mode options
enum ThemeMode: String, Codable, CaseIterable {
    case light = "LIGHT"
    case dark = "DARK"
    case system = "SYSTEM"

    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
}

/// Repeat mode
enum RepeatMode: String, Codable, CaseIterable {
    case off = "OFF"
    case all = "ALL"
    case one = "ONE"

    var displayName: String {
        switch self {
        case .off: return "Off"
        case .all: return "All"
        case .one: return "One"
        }
    }
}

/// Sleep timer presets
enum SleepTimerPreset: TimeInterval, CaseIterable {
    case none = 0
    case fiveMinutes = 300
    case tenMinutes = 600
    case fifteenMinutes = 900
    case thirtyMinutes = 1800
    case fortyFiveMinutes = 2700
    case oneHour = 3600
    case twoHours = 7200

    var displayName: String {
        switch self {
        case .none: return "Off"
        case .fiveMinutes: return "5 minutes"
        case .tenMinutes: return "10 minutes"
        case .fifteenMinutes: return "15 minutes"
        case .thirtyMinutes: return "30 minutes"
        case .fortyFiveMinutes: return "45 minutes"
        case .oneHour: return "1 hour"
        case .twoHours: return "2 hours"
        }
    }
}
