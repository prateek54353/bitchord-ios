import Foundation

/// Defines a client identity used to query YouTube's /player endpoint.
/// Ported from the Android reference (`PlayerClient.kt`).
/// Different client identities yield different formats, cipher states, and stream URLs.
struct PlayerClient: Hashable {
    let name: String
    let version: String
    let userAgent: String
    let origin: String?
    let osName: String?
    let osVersion: String?
    let deviceModel: String?
    let platform: String?

    init(
        name: String,
        version: String,
        userAgent: String,
        origin: String? = nil,
        osName: String? = nil,
        osVersion: String? = nil,
        deviceModel: String? = nil,
        platform: String? = nil
    ) {
        self.name = name
        self.version = version
        self.userAgent = userAgent
        self.origin = origin
        self.osName = osName
        self.osVersion = osVersion
        self.deviceModel = deviceModel
        self.platform = platform
    }

    var referer: String? {
        guard let origin = origin else { return nil }
        return "\(origin)/"
    }

    /// Headers that must accompany a media range request for a URL minted by this client.
    func mediaHeaders() -> [String: String] {
        var headers: [String: String] = ["User-Agent": userAgent]
        if let origin = origin {
            headers["Origin"] = origin
        }
        if let referer = referer {
            headers["Referer"] = referer
        }
        return headers
    }

    // MARK: - Client Catalog

    /// VISIONOS 1.02 — Leads InnerTubeX's catalog. Proven to return direct, playable googlevideo URLs
    /// without requiring a PO token or SABR adapter.
    static let visionOS = PlayerClient(
        name: "VISIONOS",
        version: "1.02",
        userAgent: "Mozilla/5.0 (Apple Vision; CPU 1_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/1.0 Safari/605.1.15",
        origin: nil,
        osName: "VISION_OS",
        osVersion: "1.0",
        deviceModel: "RealityDevice14,1",
        platform: "MOBILE"
    )

    /// iOS native client fallback
    static let ios = PlayerClient(
        name: "IOS",
        version: "21.26.4",
        userAgent: "com.google.ios.youtube/21.26.4 (iPhone16,2; U; CPU iOS 18_3_2 like Mac OS X;)",
        origin: nil
    )

    /// iOS native client (recent version)
    static let iosRecent = PlayerClient(
        name: "IOS",
        version: "21.29.1",
        userAgent: "com.google.ios.youtube/21.29.1 (iPhone16,2; U; CPU iOS 18_5 like Mac OS X;)",
        origin: nil
    )

    /// Android Music client
    static let androidMusic = PlayerClient(
        name: "ANDROID_MUSIC",
        version: "8.39.42",
        userAgent: "com.google.android.apps.youtube.music/8.39.42 (Linux; U; Android 15; en_US; Pixel 9 Pro; Build/AP4A.250205.002) gzip",
        origin: nil
    )

    /// Android VR client
    static let androidVr = PlayerClient(
        name: "ANDROID_VR",
        version: "1.65.10",
        userAgent: "com.google.android.apps.youtube.vr.oculus/1.65.10 (Linux; U; Android 12L; eureka-user Build/SQ3A.220605.009.A1) gzip",
        origin: nil
    )

    /// Web Remix (YouTube Music web) — requires cookies/SAPISID when playing age-gated content
    static let webRemix = PlayerClient(
        name: "WEB_REMIX",
        version: "1.20250101.01.00",
        userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36",
        origin: "https://music.youtube.com"
    )

    /// Recommended resolution candidates in priority order (VISIONOS first per Android/web reference)
    static let playbackCandidates: [PlayerClient] = [
        .visionOS,
        .ios,
        .androidMusic,
        .androidVr
    ]

    /// Signed-in playback candidates: lead with WEB_REMIX because it honors the SAPISID session
    static let signedPlaybackCandidates: [PlayerClient] = [
        .webRemix,
        .visionOS,
        .ios
    ]
}
