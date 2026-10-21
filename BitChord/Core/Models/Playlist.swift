import Foundation

/// User playlist
struct UserPlaylist: Identifiable, Codable, Hashable {
    let id: String
    let playlistId: String
    let title: String
    let description: String?
    let thumbnailUrl: String?
    let trackCount: Int
    var isPinned: Bool
    let isEditable: Bool
    let lastModified: Date?

    init(
        playlistId: String,
        title: String,
        description: String? = nil,
        thumbnailUrl: String? = nil,
        trackCount: Int = 0,
        isPinned: Bool = false,
        isEditable: Bool = true,
        lastModified: Date? = nil
    ) {
        self.id = playlistId
        self.playlistId = playlistId
        self.title = title
        self.description = description
        self.thumbnailUrl = thumbnailUrl
        self.trackCount = trackCount
        self.isPinned = isPinned
        self.isEditable = isEditable
        self.lastModified = lastModified
    }

    func artworkAt(px: Int) -> String? {
        thumbnailUrl?.artworkAt(px: px)
    }
}

/// Like status for a track
enum LikeStatus: String, Codable, CaseIterable {
    case liked = "LIKED"
    case disliked = "DISLIKED"
    case indifferent = "INDIFFERENT"
}

/// UI state wrapper for asynchronous operations
enum UiState<T> {
    case loading
    case loaded(T)
    case error(String)

    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }

    var value: T? {
        if case .loaded(let value) = self {
            return value
        }
        return nil
    }

    var error: String? {
        if case .error(let message) = self {
            return message
        }
        return nil
    }
}

/// Provide Equatable only when the associated value supports it.
extension UiState: Equatable where T: Equatable {}

/// Library view type
enum LibraryViewType: String, Codable, CaseIterable {
    case list = "LIST"
    case grid = "GRID"
}

/// Library sort options
enum LibrarySort: String, Codable, CaseIterable {
    case recent = "RECENT"
    case alphabetical = "ALPHABETICAL"
    case artist = "ARTIST"
    case album = "ALBUM"
    case duration = "DURATION"
}
