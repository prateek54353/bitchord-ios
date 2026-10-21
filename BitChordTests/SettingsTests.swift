import XCTest
@testable import BitChord

final class SettingsTests: XCTestCase {
    var settingsManager: SettingsManager!

    override func setUp() {
        super.setUp()
        settingsManager = SettingsManager()
    }

    override func tearDown() {
        settingsManager = nil
        super.tearDown()
    }

    // MARK: - Playback Settings

    func testAudioQualityWiFi() {
        settingsManager.setAudioQualityWiFi(.lossless)
        XCTAssertEqual(settingsManager.settings.audioQualityWiFi, .lossless)
    }

    func testAudioQualityMobile() {
        settingsManager.setAudioQualityMobile(.high)
        XCTAssertEqual(settingsManager.settings.audioQualityMobile, .high)
    }

    func testCrossfadeDuration() {
        settingsManager.setCrossfadeDuration(5.0)
        XCTAssertEqual(settingsManager.settings.crossfadeDuration, 5.0, accuracy: 0.1)
    }

    func testPlaybackSpeed() {
        settingsManager.setPlaybackSpeed(1.5)
        XCTAssertEqual(settingsManager.settings.playbackSpeed, 1.5, accuracy: 0.1)
    }

    func testSkipSilence() {
        settingsManager.setSkipSilence(true)
        XCTAssertTrue(settingsManager.settings.skipSilence)

        settingsManager.setSkipSilence(false)
        XCTAssertFalse(settingsManager.settings.skipSilence)
    }

    func testLoudnessNormalization() {
        settingsManager.setLoudnessNormalization(true)
        XCTAssertTrue(settingsManager.settings.loudnessNormalization)
    }

    func testGaplessPlayback() {
        settingsManager.setGaplessPlayback(false)
        XCTAssertFalse(settingsManager.settings.gaplessPlayback)
    }

    func testSleepTimerDuration() {
        settingsManager.setSleepTimerDuration(1800.0)
        XCTAssertEqual(settingsManager.settings.sleepTimerDuration, 1800.0, accuracy: 1.0)
    }

    func testSleepTimerNil() {
        settingsManager.setSleepTimerDuration(nil)
        XCTAssertNil(settingsManager.settings.sleepTimerDuration)
    }

    // MARK: - Appearance Settings

    func testThemeMode() {
        settingsManager.setThemeMode(.dark)
        XCTAssertEqual(settingsManager.settings.themeMode, .dark)
    }

    func testArtworkDrivenTheming() {
        settingsManager.setArtworkDrivenTheming(false)
        XCTAssertFalse(settingsManager.settings.artworkDrivenTheming)
    }

    // MARK: - Library Settings

    func testHomeRecentsViewType() {
        settingsManager.setHomeRecentsViewType(.grid)
        XCTAssertEqual(settingsManager.settings.homeRecentsViewType, .grid)
    }

    func testLibrarySort() {
        settingsManager.setLibrarySort(.alphabetical)
        XCTAssertEqual(settingsManager.settings.librarySort, .alphabetical)
    }

    func testSwipeToPlayNext() {
        settingsManager.setSwipeToPlayNext(true)
        XCTAssertTrue(settingsManager.settings.swipeToPlayNext)
    }

    func testPinnedPlaylists() {
        let playlistIds = ["playlist1", "playlist2", "playlist3"]
        settingsManager.setPinnedPlaylists(playlistIds)
        XCTAssertEqual(settingsManager.settings.pinnedPlaylists, playlistIds)
    }

    // MARK: - Integration Settings

    func testLastfmScrobbleEnabled() {
        settingsManager.setLastfmScrobbleEnabled(true)
        XCTAssertTrue(settingsManager.settings.lastfmScrobbleEnabled)
    }

    func testLastfmApiKey() {
        settingsManager.setLastfmApiKey("test_api_key")
        XCTAssertEqual(settingsManager.settings.lastfmApiKey, "test_api_key")
    }

    func testLastfmSecret() {
        settingsManager.setLastfmSecret("test_secret")
        XCTAssertEqual(settingsManager.settings.lastfmSecret, "test_secret")
    }

    func testLastfmEndpoint() {
        settingsManager.setLastfmEndpoint("https://custom.endpoint.com")
        XCTAssertEqual(settingsManager.settings.lastfmEndpoint, "https://custom.endpoint.com")
    }

    func testListenBrainzEnabled() {
        settingsManager.setListenBrainzEnabled(true)
        XCTAssertTrue(settingsManager.settings.listenBrainzEnabled)
    }

    func testListenBrainzToken() {
        settingsManager.setListenBrainzToken("test_token")
        XCTAssertEqual(settingsManager.settings.listenBrainzToken, "test_token")
    }

    func testDiscordRichPresenceEnabled() {
        settingsManager.setDiscordRichPresenceEnabled(true)
        XCTAssertTrue(settingsManager.settings.discordRichPresenceEnabled)
    }

    // MARK: - Source Settings

    func testUseModuleSources() {
        settingsManager.setUseModuleSources(true)
        XCTAssertTrue(settingsManager.settings.useModuleSources)
    }

    func testPreferredSourceId() {
        settingsManager.setPreferredSourceId("source_123")
        XCTAssertEqual(settingsManager.settings.preferredSourceId, "source_123")
    }

    // MARK: - Party Settings

    func testPartyServerUrl() {
        settingsManager.setPartyServerUrl("https://custom.server.com")
        XCTAssertEqual(settingsManager.settings.partyServerUrl, "https://custom.server.com")
    }

    // MARK: - Default Values

    func testDefaultSettings() {
        XCTAssertEqual(settingsManager.settings.audioQualityWiFi, .high)
        XCTAssertEqual(settingsManager.settings.audioQualityMobile, .medium)
        XCTAssertEqual(settingsManager.settings.crossfadeDuration, 3.0, accuracy: 0.1)
        XCTAssertEqual(settingsManager.settings.playbackSpeed, 1.0, accuracy: 0.1)
        XCTAssertFalse(settingsManager.settings.skipSilence)
        XCTAssertTrue(settingsManager.settings.loudnessNormalization)
        XCTAssertTrue(settingsManager.settings.gaplessPlayback)
        XCTAssertEqual(settingsManager.settings.themeMode, .system)
        XCTAssertTrue(settingsManager.settings.artworkDrivenTheming)
        XCTAssertEqual(settingsManager.settings.homeRecentsViewType, .list)
        XCTAssertEqual(settingsManager.settings.librarySort, .recent)
        XCTAssertFalse(settingsManager.settings.swipeToPlayNext)
        XCTAssertTrue(settingsManager.settings.pinnedPlaylists.isEmpty)
        XCTAssertFalse(settingsManager.settings.lastfmScrobbleEnabled)
        XCTAssertFalse(settingsManager.settings.listenBrainzEnabled)
        XCTAssertFalse(settingsManager.settings.discordRichPresenceEnabled)
        XCTAssertFalse(settingsManager.settings.useModuleSources)
        XCTAssertNil(settingsManager.settings.preferredSourceId)
    }
}
