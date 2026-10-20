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
        let url = URL(string: "\(baseURL)/api/get?artist_name=\(song.artist.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&track_name=\(song.title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&duration=\(duration)")!

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
        let searchURL = URL(string: "\(baseURL)/api/search/multi?q=\(searchQuery)")!

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

        // Extract lyrics from HTML (simplified - in production, use proper HTML parsing)
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
        // This is a simplified extraction - in production, use proper HTML parsing
        let pattern = #"<div class="lyrics">.*?<p>(.*?)</p>.*?</div>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return ""
        }

        let range = NSRange(html.startIndex..., in: html)
        if let match = regex.firstMatch(in: html, range: range) {
            let lyrics = (html as NSString).substring(with: match.range(at: 1))
            return lyrics.replacingOccurrences(of: "<[^>]+", with: "", options: .regularExpression)
        }

        return ""
    }
}

/// Lyrics manager with provider fallback
class LyricsManager {
    private let providers: [LyricsProviderProtocol]

    init(providers: [LyricsProviderProtocol] = [LRCLIBProvider(), GeniusProvider()]) {
        self.providers = providers
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
}

enum LyricsError: Error {
    case notFound
    case invalidResponse
    case networkError
}
