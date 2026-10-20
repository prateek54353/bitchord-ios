import Foundation

/// A single lyric line with timing information
struct LyricLine: Identifiable, Codable, Hashable {
    let id: String
    let text: String
    let startTime: TimeInterval  // in seconds
    let duration: TimeInterval?  // optional duration for word-level sync
    let words: [LyricWord]?     // word-level timing for Apple-style highlighting

    init(
        text: String,
        startTime: TimeInterval,
        duration: TimeInterval? = nil,
        words: [LyricWord]? = nil
    ) {
        self.id = UUID().uuidString
        self.text = text
        self.startTime = startTime
        self.duration = duration
        self.words = words
    }
}

/// Word-level timing for synced lyrics
struct LyricWord: Identifiable, Codable, Hashable {
    let id: String
    let text: String
    let startTime: TimeInterval
    let duration: TimeInterval

    init(text: String, startTime: TimeInterval, duration: TimeInterval) {
        self.id = UUID().uuidString
        self.text = text
        self.startTime = startTime
        self.duration = duration
    }
}

/// Complete lyrics for a track
struct Lyrics: Identifiable, Codable {
    let id: String
    let lines: [LyricLine]
    let provider: LyricsProvider
    let isSynced: Bool
    let hasTranslation: Bool
    let offset: TimeInterval  // manual offset in seconds

    init(
        lines: [LyricLine],
        provider: LyricsProvider,
        isSynced: Bool = true,
        hasTranslation: Bool = false,
        offset: TimeInterval = 0
    ) {
        self.id = UUID().uuidString
        self.lines = lines
        self.provider = provider
        self.isSynced = isSynced
        self.hasTranslation = hasTranslation
        self.offset = offset
    }

    /// Find the active lyric line at a given playback time
    func activeLine(at time: TimeInterval) -> LyricLine? {
        let adjustedTime = time + offset
        return lines.last { $0.startTime <= adjustedTime }
    }

    /// Find the active word at a given playback time
    func activeWord(at time: TimeInterval) -> LyricWord? {
        guard let line = activeLine(at: time),
              let words = line.words else { return nil }

        let adjustedTime = time + offset
        return words.last { $0.startTime <= adjustedTime }
    }
}

/// Lyrics provider sources
enum LyricsProvider: String, Codable, CaseIterable {
    case lrcRed = "LRC_RED"
    case biniLyrics = "BINI_LYRICS"
    case betterLyrics = "BETTER_LYRICS"
    case lrclib = "LRCLIB"
    case genius = "GENIUS"
    case kuGou = "KUGOU"
    case megalobiz = "MEGALOBIZ"
    case musixmatch = "MUSIXMATCH"
    case paxSenix = "PAXSENIX"
    case lyricsPlus = "LYRICS_PLUS"
    case simpMusic = "SIMPMUSIC"
    case unison = "UNISON"

    var displayName: String {
        switch self {
        case .lrcRed: return "LRC.red"
        case .biniLyrics: return "BiniLyrics"
        case .betterLyrics: return "BetterLyrics"
        case .lrclib: return "LRCLIB"
        case .genius: return "Genius"
        case .kuGou: return "KuGou"
        case .megalobiz: return "Megalobiz"
        case .musixmatch: return "Musixmatch"
        case .paxSenix: return "PaxSenix"
        case .lyricsPlus: return "LyricsPlus"
        case .simpMusic: return "SimpMusic"
        case .unison: return "Unison"
        }
    }
}

/// Parsed LRC format lyrics
struct LrcLyrics {
    let lines: [LyricLine]

    /// Parse LRC format string
    static func parse(_ lrcString: String) -> LrcLyrics {
        let lines = lrcString.components(separatedBy: .newlines)
        var parsedLines: [LyricLine] = []

        for line in lines {
            // LRC format: [mm:ss.xx] lyrics text
            let pattern = #"^\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)$"#
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {

                let minutes = Int((line as NSString).substring(with: match.range(at: 1))) ?? 0
                let seconds = Int((line as NSString).substring(with: match.range(at: 2))) ?? 0
                let centiseconds = Int((line as NSString).substring(with: match.range(at: 3))) ?? 0
                let text = (line as NSString).substring(with: match.range(at: 4)).trimmingCharacters(in: .whitespaces)

                let startTime = TimeInterval(minutes * 60 + seconds) + TimeInterval(centiseconds) / 100.0

                if !text.isEmpty {
                    parsedLines.append(LyricLine(text: text, startTime: startTime))
                }
            }
        }

        return LrcLyrics(lines: parsedLines)
    }
}
