import Foundation

/// Tier of an item in the playback queue
enum QueueTier: String, Codable, CaseIterable {
    /// Explicitly queued by user ("Play Next", "Add to Queue", or preserved user queue)
    case userQueue = "USER_QUEUE"
    /// Part of the active Album, Playlist, or Artist collection context
    case context = "CONTEXT"
    /// Dynamically generated radio recommendations appended when context/user queue ends
    case autoplay = "AUTOPLAY"
}

/// One credited artist, as YouTube Music itself states them
struct ArtistRef: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let browseId: String?

    init(name: String, browseId: String? = nil) {
        self.id = UUID().uuidString
        self.name = name
        self.browseId = browseId
    }
}

/// A playable YouTube Music track
struct Song: Identifiable, Codable, Hashable {
    let id: String
    let videoId: String
    let title: String
    let artist: String
    let thumbnailUrl: String?
    let durationText: String?

    // Browse ids lifted from the row, used by the long-press actions
    let artistId: String?
    // Every credited artist, each with their own channel
    let artists: [ArtistRef]
    let albumId: String?
    let albumName: String?

    // A music-video upload rather than the catalogue track
    let isVideo: Bool
    let isVideoOrigin: Bool

    // This track's identity within one playlist
    let setVideoId: String?

    // Which queue tier this track belongs to
    let queueTier: QueueTier

    // Unique queue-entry identity
    let queueEntryId: String?

    // The seed title of an explicitly started radio queue
    let radioName: String?

    // Explicit content or file URI for local device tracks
    let localUri: String?
    let localPath: String?

    // MediaStore timestamps
    let localDateAddedSeconds: Int64?
    let localDateModifiedSeconds: Int64?

    // Track number within its album
    let trackNumber: Int?

    // Source quality information
    let sourceQuality: String?
    let sourceHiRes: Bool

    // Explicit content state
    let isExplicit: Bool?

    // The page that put this track in the queue
    let playbackSource: String?
    let playbackSourceType: PlaybackSourceType?
    let playbackSourceId: String?

    init(
        videoId: String,
        title: String,
        artist: String,
        thumbnailUrl: String? = nil,
        durationText: String? = nil,
        artistId: String? = nil,
        artists: [ArtistRef] = [],
        albumId: String? = nil,
        albumName: String? = nil,
        isVideo: Bool = false,
        isVideoOrigin: Bool = false,
        setVideoId: String? = nil,
        queueTier: QueueTier = .context,
        queueEntryId: String? = nil,
        radioName: String? = nil,
        localUri: String? = nil,
        localPath: String? = nil,
        localDateAddedSeconds: Int64? = nil,
        localDateModifiedSeconds: Int64? = nil,
        trackNumber: Int? = nil,
        sourceQuality: String? = nil,
        sourceHiRes: Bool = false,
        isExplicit: Bool? = nil,
        playbackSource: String? = nil,
        playbackSourceType: PlaybackSourceType? = nil,
        playbackSourceId: String? = nil
    ) {
        self.id = videoId
        self.videoId = videoId
        self.title = title
        self.artist = artist
        self.thumbnailUrl = thumbnailUrl
        self.durationText = durationText
        self.artistId = artistId
        self.artists = artists
        self.albumId = albumId
        self.albumName = albumName
        self.isVideo = isVideo
        self.isVideoOrigin = isVideoOrigin
        self.setVideoId = setVideoId
        self.queueTier = queueTier
        self.queueEntryId = queueEntryId ?? UUID().uuidString
        self.radioName = radioName
        self.localUri = localUri
        self.localPath = localPath
        self.localDateAddedSeconds = localDateAddedSeconds
        self.localDateModifiedSeconds = localDateModifiedSeconds
        self.trackNumber = trackNumber
        self.sourceQuality = sourceQuality
        self.sourceHiRes = sourceHiRes
        self.isExplicit = isExplicit
        self.playbackSource = playbackSource
        self.playbackSourceType = playbackSourceType
        self.playbackSourceId = playbackSourceId
    }

    /// Legacy derived property: true if and only if queueTier is autoplay
    var fromAutoplay: Bool {
        queueTier == .autoplay
    }

    /// Song.durationText in milliseconds, or 0 when the row didn't state one
    func durationMillis() -> Int64 {
        durationText?.durationMillis() ?? 0
    }

    /// Artwork at a given pixel size
    func artworkAt(px: Int) -> String? {
        thumbnailUrl?.artworkAt(px: px)
    }

    /// Whether a row is the track the player is on
    func isSameTrackAs(other: Song?) -> Bool {
        guard let other = other else { return false }
        return title == other.title && artist == other.artist
    }
}

extension String {
    /// As Song.durationMillis, for a M:SS or H:MM:SS string on its own
    func durationMillis() -> Int64 {
        let parts = self.trimmingCharacters(in: .whitespaces).split(separator: ":")
        guard parts.count == 2 || parts.count == 3 else { return 0 }

        let numbers = parts.compactMap { Int64($0) }
        guard numbers.count == parts.count else { return 0 }

        let seconds: Int64
        if numbers.count == 2 {
            seconds = numbers[0] * 60 + numbers[1]
        } else {
            seconds = numbers[0] * 3600 + numbers[1] * 60 + numbers[2]
        }

        return max(0, seconds * 1000)
    }

    /// As Song.artworkAt, for artwork that isn't a track's
    func artworkAt(px: Int) -> String {
        var sized = self
        let sizePattern = "w\\d+-h\\d+"
        let paramPattern = "=s\\d+"

        if let regex = try? NSRegularExpression(pattern: sizePattern, options: []) {
            let range = NSRange(sized.startIndex..., in: sized)
            sized = regex.stringByReplacingMatches(in: sized, options: [], range: range, withTemplate: "w\(px)-h\(px)")
        }

        if isGoogleImageHost(self) {
            if let regex = try? NSRegularExpression(pattern: paramPattern, options: []) {
                let range = NSRange(sized.startIndex..., in: sized)
                sized = regex.stringByReplacingMatches(in: sized, options: [], range: range, withTemplate: "=s\(px)")
            }
        }

        return sized
    }

    private func isGoogleImageHost(_ url: String) -> Bool {
        let host = url
            .dropFirst(NSString(string: url).range(of: "://").location + 3)
            .components(separatedBy: "/").first?
            .components(separatedBy: ":").first?
            .lowercased() ?? ""

        return host == "ggpht.com" ||
               host.hasSuffix(".ggpht.com") ||
               host == "googleusercontent.com" ||
               host.hasSuffix(".googleusercontent.com")
    }
}

/// Artwork size constants
extension Song {
    /// Artwork for a list row - 52dp at most, so about 160px on a 3x screen
    static let rowArtPx = 160

    /// Artwork for a shelf card: 166dp wide, so about 480px at 3x
    static let cardArtPx = 480

    /// Artwork for a page header, drawn near enough full width
    static let headerArtPx = 720

    /// Artwork handed to the media session - lock screen, notification, Android Auto
    static let notificationArtPx = 544

    /// Artwork for the full player - the largest rung on the ladder
    static let playerArtPx = 1200
}

/// A queue-level origin shown above Now Playing
enum PlaybackSourceType: String, Codable, CaseIterable {
    case home = "HOME"
    case search = "SEARCH"
    case history = "HISTORY"
    case replay = "REPLAY"
    case explore = "EXPLORE"
    case browse = "BROWSE"
    case sharedLink = "SHARED_LINK"
    case queue = "QUEUE"
}
