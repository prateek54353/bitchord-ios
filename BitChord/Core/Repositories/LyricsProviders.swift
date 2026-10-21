import Foundation

/// Lyrics provider interface
protocol LyricsProviderProtocol {
    var providerType: LyricsProvider { get }
    func fetchLyrics(for song: Song) async throws -> Lyrics
}

/// LRCLIB lyrics provider
class LRCLIBProvider: LyricsProviderProtocol {
    let providerType: LyricsProvider = .lrclib
    private let httpClient: HttpClient
    private let baseURL = "https://lrclib.net"

    init(httpClient: HttpClient = HttpClient()) {
        self.httpClient = httpClient
    }

    func fetchLyrics(for song: Song) async throws -> Lyrics {
        // Try exact match first
        let duration = song.durationMillis() / 1000
        let encodedArtist = song.artist.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedTitle = song.title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        let url = URL(string: "\(baseURL)/api/get?artist_name=\(encodedArtist)&track_name=\(encodedTitle)&duration=\(duration)")!

        let data = try await httpClient.get(url: url)

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let syncedLyrics = json["syncedLyrics"] as? String,
           !syncedLyrics.isEmpty {
            let parsed = LrcLyrics.parse(syncedLyrics)
            return Lyrics(
                lines: parsed.lines,
                provider: .lrclib,
                isSynced: true
            )
        }

        // Fallback to plain lyrics
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let plainLyrics = json["plainLyrics"] as? String,
           !plainLyrics.isEmpty {
            let lines = plainLyrics.components(separatedBy: .newlines)
                .filter { !$0.isEmpty }
                .map { LyricLine(text: $0, startTime: 0) }
            return Lyrics(
                lines: lines,
                provider: .lrclib,
                isSynced: false
            )
        }

        throw LyricsError.notFound
    }
}

/// Genius lyrics provider
class GeniusProvider: LyricsProviderProtocol {
    let providerType: LyricsProvider = .genius
    private let httpClient: HttpClient
    private let baseURL = "https://genius.com"

    init(httpClient: HttpClient = HttpClient()) {
        self.httpClient = httpClient
    }

    func fetchLyrics(for song: Song) async throws -> Lyrics {
        // Search for the song
        let searchQuery = "\(song.artist) \(song.title)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let searchURL = URL(string: "\(baseURL)/api/search/multi?q=\(searchQuery)") else {
            throw LyricsError.invalidResponse
        }

        let data = try await httpClient.get(url: searchURL)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let response = json["response"] as? [String: Any],
              let hits = response["hits"] as? [[String: Any]] else {
            throw LyricsError.notFound
        }

        // Find the first song result
        guard let hit = hits.first,
              let result = hit["result"] as? [String: Any],
              let path = result["path"] as? String else {
            throw LyricsError.notFound
        }

        // Fetch the song page
        let songURL = URL(string: "\(baseURL)\(path)")!
        let songData = try await httpClient.get(url: songURL)

        guard let html = String(data: songData, encoding: .utf8) else {
            throw LyricsError.invalidResponse
        }

        // Extract lyrics from HTML
        let lyrics = extractLyrics(from: html)

        let lines = lyrics.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
            .map { LyricLine(text: $0, startTime: 0) }

        return Lyrics(
            lines: lines,
            provider: .genius,
            isSynced: false
        )
    }

    private func extractLyrics(from html: String) -> String {
        // Try multiple patterns for lyrics extraction
        let patterns = [
            #"<div class="lyrics">.*?<div data-lyrics-container="true">(.*?)</div>.*?</div>"#,
            #"<div class="lyrics">.*?<p>(.*?)</p>.*?</div>"#,
            #"<div class="Lyrics__Container.*?>(.*?)</div>"#
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
                continue
            }

            let range = NSRange(html.startIndex..., in: html)
            if let match = regex.firstMatch(in: html, range: range) {
                let lyrics = (html as NSString).substring(with: match.range(at: 1))
                let cleaned = lyrics.replacingOccurrences(of: "<[^>]+", with: "", options: .regularExpression)
                    .replacingOccurrences(of: "&amp;", with: "&")
                    .replacingOccurrences(of: "&lt;", with: "<")
                    .replacingOccurrences(of: "&gt;", with: ">")
                    .replacingOccurrences(of: "&quot;", with: "\"")
                if !cleaned.isEmpty {
                    return cleaned
                }
            }
        }

        return ""
    }
}

/// Musixmatch lyrics provider (requires API key)
class MusixmatchProvider: LyricsProviderProtocol {
    let providerType: LyricsProvider = .musixmatch
    private let httpClient: HttpClient
    private let baseURL = "https://api.musixmatch.com/ws/1.1"
    private let apiKey: String?

    init(httpClient: HttpClient = HttpClient(), apiKey: String? = nil) {
        self.httpClient = httpClient
        self.apiKey = apiKey
    }

    func fetchLyrics(for song: Song) async throws -> Lyrics {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw LyricsError.notFound
        }

        // Search for track
        let encodedTitle = song.title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedArtist = song.artist.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let searchURL = URL(string: "\(baseURL)/matcher.track.get?format=json&q_track=\(encodedTitle)&q_artist=\(encodedArtist)&apikey=\(apiKey)") else {
            throw LyricsError.invalidResponse
        }

        let data = try await httpClient.get(url: searchURL)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let message = json["message"] as? [String: Any],
              let body = message["body"] as? [String: Any],
              let track = body["track"] as? [String: Any],
              let trackId = track["track_id"] as? Int else {
            throw LyricsError.notFound
        }

        // Get lyrics
        let lyricsURL = URL(string: "\(baseURL)/track.lyrics.get?format=json&track_id=\(trackId)&apikey=\(apiKey)")!
        let lyricsData = try await httpClient.get(url: lyricsURL)

        guard let lyricsJson = try? JSONSerialization.jsonObject(with: lyricsData) as? [String: Any],
              let lyricsMessage = lyricsJson["message"] as? [String: Any],
              let lyricsBody = lyricsMessage["body"] as? [String: Any],
              let lyricsList = lyricsBody["lyrics"] as? [String: Any],
              let lyricsBodyText = lyricsList["lyrics_body"] as? String else {
            throw LyricsError.notFound
        }

        let lines = lyricsBodyText.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
            .map { LyricLine(text: $0, startTime: 0) }

        return Lyrics(
            lines: lines,
            provider: .musixmatch,
            isSynced: false
        )
    }
}

/// Lyrics manager with provider fallback
class LyricsManager {
    static let shared = LyricsManager()

    private let providers: [LyricsProviderProtocol]

    init(providers: [LyricsProviderProtocol]? = nil) {
        // Default providers in priority order
        self.providers = providers ?? [
            LRCLIBProvider(),
            GeniusProvider()
        ]
    }

    func fetchLyrics(for song: Song) async throws -> Lyrics {
        for provider in providers {
            do {
                let lyrics = try await provider.fetchLyrics(for: song)
                return lyrics
            } catch {
                // Try next provider
                continue
            }
        }

        throw LyricsError.notFound
    }

    func fetchSyncedLyrics(for song: Song) async throws -> Lyrics {
        // Only try LRCLIB for synced lyrics
        let lrclib = LRCLIBProvider()
        return try await lrclib.fetchLyrics(for: song)
    }
}

enum LyricsError: Error {
    case notFound
    case invalidResponse
    case networkError
}
