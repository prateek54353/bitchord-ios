import Foundation

/// Tracks playback events for YouTube Music recommendations
/// Based on Android's PlaybackTracker.kt
class PlaybackTracker {
    static let shared = PlaybackTracker()

    private let innerTubeClient: InnerTubeClient
    private var playbackContext: PlaybackContext?

    struct PlaybackContext: Codable {
        let videoId: String
        let playlistId: String?
        let playlistIndex: Int?
        let logTime: Int64
        let playDuration: Int
        let playbackRate: Float
    }

    init(innerTubeClient: InnerTubeClient = .shared) {
        self.innerTubeClient = innerTubeClient
    }

    /// Start tracking a song
    func startPlayback(videoId: String, playlistId: String? = nil, playlistIndex: Int? = nil) {
        playbackContext = PlaybackContext(
            videoId: videoId,
            playlistId: playlistId,
            playlistIndex: playlistIndex,
            logTime: Int64(Date().timeIntervalSince1970),
            playDuration: 0,
            playbackRate: 1.0
        )
    }

    /// Update playback duration (called periodically)
    func updatePlayback(duration: Int, rate: Float = 1.0) {
        playbackContext?.playDuration = duration
        playbackContext?.playbackRate = rate
    }

    /// Stop tracking and send playback event to YouTube Music
    func endPlayback() async {
        guard let context = playbackContext else { return }

        do {
            try await sendPlaybackEvent(context)
        } catch {
            print("Failed to send playback event: \(error)")
        }

        playbackContext = nil
    }

    private func sendPlaybackEvent(_ context: PlaybackContext) async throws {
        let body: [String: Any] = [
            "context": buildContext(),
            "playbackContext": [
                "videoId": context.videoId,
                "playlistId": context.playlistId ?? "",
                "playlistIndex": context.playlistIndex ?? 0,
                "currentUrl": context.videoId,
                "currentUrlEndpoint": [
                    "watchEndpoint": [
                        "videoId": context.videoId
                    ]
                ]
            ],
            "playbackTracking": [
                "videostatsWatchtime": [
                    "elapsedTime": context.playDuration,
                    "duration": context.playDuration
                ],
                "logTime": context.logTime,
                "playbackRate": context.playbackRate
            ]
        ]

        _ = try await innerTubeClient.sendRequest(endpoint: "playback", body: body)
    }

    private func buildContext() -> [String: Any] {
        // This should match the context built in InnerTubeClient
        return [
            "client": [
                "clientName": "IOS_MUSIC",
                "clientVersion": "6.37.1",
                "hl": "en",
                "gl": "US"
            ]
        ]
    }
}
