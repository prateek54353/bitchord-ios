import Foundation

/// Stream resolver for YouTube Music stream URLs
class StreamResolver {
    private let innerTubeClient: InnerTubeClient

    init(innerTubeClient: InnerTubeClient = InnerTubeClient()) {
        self.innerTubeClient = innerTubeClient
    }

    // MARK: - Stream Resolution

    func resolveStreamUrl(videoId: String) async throws -> StreamInfo {
        let body: [String: Any] = [
            "videoId": videoId,
            "playbackContext": [
                "contentPlaybackContext": [
                    "vis": 0,
                    "lactMilliseconds": "-1"
                ]
            ],
            "contentCheckOk": true,
            "racyCheckOk": true
        ]

        let response = try await innerTubeClient.sendRequest(endpoint: "player", body: body)

        guard let streamingData = response["streamingData"] as? [String: Any],
              let formats = streamingData["formats"] as? [[String: Any]] else {
            throw StreamError.noFormatsAvailable
        }

        // Parse formats and select best quality
        let parsedFormats = formats.compactMap { parseFormat($0) }
        let bestFormat = selectBestFormat(from: parsedFormats)

        guard let format = bestFormat else {
            throw StreamError.noSuitableFormat
        }

        // Extract video details
        let videoDetails = extractVideoDetails(from: response)

        return StreamInfo(
            url: format.url,
            mimeType: format.mimeType,
            bitrate: format.bitrate,
            itag: format.itag,
            quality: format.quality,
            duration: videoDetails.duration,
            title: videoDetails.title,
            author: videoDetails.author
        )
    }

    // MARK: - Format Parsing

    private func parseFormat(_ dict: [String: Any]) -> Format? {
        guard let url = dict["url"] as? String,
              let mimeType = dict["mimeType"] as? String,
              let itag = dict["itag"] as? Int else {
            return nil
        }

        let bitrate = dict["bitrate"] as? Int
        let quality = dict["quality"] as? String

        return Format(
            url: url,
            mimeType: mimeType,
            bitrate: bitrate,
            itag: itag,
            quality: quality
        )
    }

    // MARK: - Format Selection

    private func selectBestFormat(from formats: [Format]) -> Format? {
        // Prefer audio-only formats for music
        let audioFormats = formats.filter { $0.mimeType.contains("audio") }

        if !audioFormats.isEmpty {
            // Select highest bitrate audio
            return audioFormats.max { $0.bitrate ?? 0 < $1.bitrate ?? 0 }
        }

        // Fallback to any format
        return formats.first
    }

    // MARK: - Video Details Extraction

    private func extractVideoDetails(from response: [String: Any]) -> VideoDetails {
        var duration: TimeInterval = 0
        var title = ""
        var author = ""

        if let videoDetails = response["videoDetails"] as? [String: Any] {
            title = videoDetails["title"] as? String ?? ""
            author = videoDetails["author"] as? String ?? ""

            if let lengthSeconds = videoDetails["lengthSeconds"] as? String,
               let seconds = Double(lengthSeconds) {
                duration = seconds
            }
        }

        return VideoDetails(
            duration: duration,
            title: title,
            author: author
        )
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

enum StreamError: Error {
    case noFormatsAvailable
    case noSuitableFormat
    case invalidResponse
}
