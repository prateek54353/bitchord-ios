import Foundation

/// Resolves playable audio stream URLs from YouTube Music video IDs.
/// Employs a multi-client fallback strategy (VISIONOS -> IOS -> ANDROID_MUSIC -> ANDROID_VR),
/// mirroring the reference Android app's InnerTubeX / StreamResolver approach.
class StreamResolver {
    static let shared = StreamResolver()

    private let innerTubeClient: InnerTubeClient

    // Cache for resolved stream URLs
    private var recentCache: [String: CachedStream] = [:]
    // Cache for permanently unplayable tracks
    private var unplayableCache: [String: UnplayableVerdict] = [:]

    // Constants
    private let urlTtlMs: Int64 = 3_600_000 // 1 hour
    private let unplayableTtlMs: Int64 = 10 * 60 * 1000 // 10 minutes
    private let maxCached = 64

    // Bitrate ceiling - can be set from settings
    var maxKbps: Int = Int.max

    private init(innerTubeClient: InnerTubeClient = .shared) {
        self.innerTubeClient = innerTubeClient
    }

    // MARK: - Public API

    /// Resolves direct stream URL and metadata for a video ID
    func resolveStreamUrl(videoId: String) async throws -> StreamInfo {
        // Check cache first
        if let cached = recentCache[videoId] {
            let now = Int64(Date().timeIntervalSince1970 * 1000)
            if now - cached.timestamp < urlTtlMs {
                return cached.streamInfo
            }
        }

        // Check if permanently unplayable
        if let verdict = unplayableCache[videoId] {
            let now = Int64(Date().timeIntervalSince1970 * 1000)
            if now - verdict.timestamp < unplayableTtlMs {
                throw StreamError.unplayable(verdict.reason)
            } else {
                unplayableCache.removeValue(forKey: videoId)
            }
        }

        var lastError: Error = StreamError.noFormatsAvailable

        for client in PlayerClient.playbackCandidates {
            do {
                if let streamInfo = try await requestStream(videoId: videoId, client: client) {
                    // Cache the result
                    cacheStream(videoId: videoId, streamInfo: streamInfo)
                    return streamInfo
                }
            } catch let error as StreamError {
                lastError = error
                // If permanently age-restricted, don't keep hammering
                if case .ageRestricted = error {
                    rememberUnplayable(videoId: videoId, reason: "Age restricted")
                    throw error
                }
            } catch {
                lastError = error
            }
        }

        // Mark as unplayable if all clients failed
        rememberUnplayable(videoId: videoId, reason: lastError.localizedDescription)
        throw lastError
    }

    /// Get loudness normalization value for a video ID
    func loudnessDbFor(videoId: String) -> Double? {
        return recentCache[videoId]?.loudnessDb
    }

    /// Clear caches (call on session change)
    func onSessionChanged() {
        recentCache.removeAll()
        unplayableCache.removeAll()
    }

    // MARK: - Caching

    private func cacheStream(videoId: String, streamInfo: StreamInfo) {
        if recentCache.count >= maxCached {
            recentCache.removeAll()
        }

        let now = Int64(Date().timeIntervalSince1970 * 1000)
        recentCache[videoId] = CachedStream(
            streamInfo: streamInfo,
            timestamp: now,
            loudnessDb: nil // Would need to extract from response
        )
    }

    private func rememberUnplayable(videoId: String, reason: String) {
        if unplayableCache.count >= maxCached {
            unplayableCache.removeAll()
        }

        let now = Int64(Date().timeIntervalSince1970 * 1000)
        unplayableCache[videoId] = UnplayableVerdict(reason: reason, timestamp: now)
    }

    // MARK: - Player Request & Parsing

    private func requestStream(videoId: String, client: PlayerClient) async throws -> StreamInfo? {
        // Player request body: matches Android and web resolver
        // Notice: NO adPlaybackContext (preventing the 70s cutoff observed in tests)
        let body: [String: Any] = [
            "videoId": videoId,
            "contentCheckOk": true,
            "racyCheckOk": true,
            "params": "CgIQBg==", // audio-only preference parameter
            "playbackContext": [
                "contentPlaybackContext": [
                    "vis": 0,
                    "lactMilliseconds": "-1"
                ]
            ]
        ]

        let response = try await innerTubeClient.sendRequest(
            endpoint: "player",
            body: body,
            client: client
        )

        // 1. Check playability status
        if let playability = response.o("playabilityStatus") {
            let status = playability.s("status") ?? ""
            let reason = playability.s("reason") ?? ""

            if status != "OK" {
                let lowerReason = reason.lowercased()
                if lowerReason.contains("age") || lowerReason.contains("sign in") {
                    throw StreamError.ageRestricted
                }
                if status == "UNPLAYABLE" || status == "ERROR" {
                    throw StreamError.unplayable(reason.isEmpty ? status : reason)
                }
                return nil
            }
        }

        // 2. Parse streamingData
        guard let streamingData = response.o("streamingData") else {
            return nil
        }

        // Prefer adaptiveFormats (separate audio/video streams, higher quality Opus/AAC)
        let adaptiveFormats = streamingData.a("adaptiveFormats") ?? []
        let muxedFormats = streamingData.a("formats") ?? []

        let allFormatDicts = adaptiveFormats + muxedFormats
        let parsedFormats = allFormatDicts.compactMap { parseFormat($0) }

        guard !parsedFormats.isEmpty else {
            return nil
        }

        guard let bestFormat = selectBestFormat(from: parsedFormats) else {
            throw StreamError.noSuitableFormat
        }

        // 3. Extract video details
        let videoDetails = extractVideoDetails(from: response)

        return StreamInfo(
            url: bestFormat.url,
            mimeType: bestFormat.mimeType,
            bitrate: bestFormat.bitrate,
            itag: bestFormat.itag,
            quality: bestFormat.quality,
            duration: videoDetails.duration,
            title: videoDetails.title,
            author: videoDetails.author,
            headers: client.mediaHeaders(),
            clientName: client.name
        )
    }

    // MARK: - Format Selection

    private func parseFormat(_ dict: [String: Any]) -> Format? {
        // Direct URL is required. Formats requiring signature deciphering without cipher keys are skipped.
        guard let url = dict.s("url"), !url.isEmpty,
              let mimeType = dict.s("mimeType"),
              let itag = dict.i("itag") else {
            return nil
        }

        let bitrate = dict.i("bitrate")
        let quality = dict.s("qualityLabel") ?? dict.s("quality")

        return Format(
            url: url,
            mimeType: mimeType,
            bitrate: bitrate,
            itag: itag,
            quality: quality
        )
    }

    private func selectBestFormat(from formats: [Format]) -> Format? {
        // Filter for audio formats
        let audioFormats = formats.filter { $0.mimeType.contains("audio") }

        if !audioFormats.isEmpty {
            // Filter by maxKbps if set
            let candidates = maxKbps < Int.max
                ? audioFormats.filter { ($0.bitrate ?? 0) <= maxKbps }
                : audioFormats

            // Sort by bitrate descending; Opus itag 251 or AAC itag 140 will be prioritized
            return candidates.max { ($0.bitrate ?? 0) < ($1.bitrate ?? 0) }
        }

        // Fallback to highest bitrate format overall
        return formats.max { ($0.bitrate ?? 0) < ($1.bitrate ?? 0) }
    }

    // MARK: - Video Details Extraction

    private func extractVideoDetails(from response: [String: Any]) -> VideoDetails {
        var duration: TimeInterval = 0
        var title = ""
        var author = ""

        if let details = response.o("videoDetails") {
            title = details.s("title") ?? ""
            author = details.s("author") ?? ""

            if let seconds = details.s("lengthSeconds"), let d = Double(seconds) {
                duration = d
            }
        }

        return VideoDetails(duration: duration, title: title, author: author)
    }
}

// MARK: - Models

struct StreamInfo {
    let url: String
    let mimeType: String
    let bitrate: Int?
    let itag: Int
    let quality: String?
    let duration: TimeInterval
    let title: String
    let author: String
    let headers: [String: String]
    let clientName: String?

    init(
        url: String,
        mimeType: String = "audio/mp4",
        bitrate: Int? = nil,
        itag: Int = 0,
        quality: String? = nil,
        duration: TimeInterval = 0,
        title: String = "",
        author: String = "",
        headers: [String: String] = [:],
        clientName: String? = nil
    ) {
        self.url = url
        self.mimeType = mimeType
        self.bitrate = bitrate
        self.itag = itag
        self.quality = quality
        self.duration = duration
        self.title = title
        self.author = author
        self.headers = headers
        self.clientName = clientName
    }
}

struct Format {
    let url: String
    let mimeType: String
    let bitrate: Int?
    let itag: Int
    let quality: String?
}

struct VideoDetails {
    let duration: TimeInterval
    let title: String
    let author: String
}

enum StreamError: Error, Equatable {
    case noFormatsAvailable
    case noSuitableFormat
    case invalidResponse
    case unplayable(String)
    case ageRestricted
}

// MARK: - Cache Models

private struct CachedStream {
    let streamInfo: StreamInfo
    let timestamp: Int64
    let loudnessDb: Double?
}

private struct UnplayableVerdict {
    let reason: String
    let timestamp: Int64
}
