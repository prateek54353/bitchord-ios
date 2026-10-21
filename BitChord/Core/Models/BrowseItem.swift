import Foundation

/// A non-track search result: album, artist or playlist
enum BrowseType: String, Codable, CaseIterable {
    case album = "ALBUM"
    case artist = "ARTIST"
    case playlist = "PLAYLIST"
    case other = "OTHER"
}

/// A non-track search result: album, artist or playlist
struct BrowseItem: Identifiable, Codable, Hashable {
    let id: String
    let browseId: String
    let title: String
    let subtitle: String
    let thumbnailUrl: String?
    let type: BrowseType

    init(
        browseId: String,
        title: String,
        subtitle: String,
        thumbnailUrl: String? = nil,
        type: BrowseType
    ) {
        self.id = browseId
        self.browseId = browseId
        self.title = title
        self.subtitle = subtitle
        self.thumbnailUrl = thumbnailUrl
        self.type = type
    }

    func artworkAt(px: Int) -> String? {
        thumbnailUrl?.artworkAt(px: px)
    }
}

/// Search rows are heterogeneous once filters other than "Songs" are used
enum SearchResult: Identifiable, Codable {
    case topTrack(Song)
    case track(Song)
    case browse(BrowseItem)

    var id: String {
        switch self {
        case .topTrack(let song), .track(let song):
            return song.id
        case .browse(let item):
            return item.id
        }
    }
}

/// Search filter options
enum SearchFilter: String, Codable, CaseIterable {
    case all = "ALL"
    case songs = "SONGS"
    case videos = "VIDEOS"
    case albums = "ALBUMS"
    case artists = "ARTISTS"
    case playlists = "PLAYLISTS"

    var label: String {
        switch self {
        case .all: return "All"
        case .songs: return "Songs"
        case .videos: return "Videos"
        case .albums: return "Albums"
        case .artists: return "Artists"
        case .playlists: return "Playlists"
        }
    }

    var params: String? {
        switch self {
        case .all: return nil
        case .songs: return "EgWKAQIIAWoKEAkQChAFEAMQBA=="
        case .videos: return "EgWKAQIQAWoKEAkQChAFEAMQBA=="
        case .albums: return "EgWKAQIYAWoKEAkQChAFEAMQBA=="
        case .artists: return "EgWKAQIgAWoKEAkQChAFEAMQBA=="
        case .playlists: return "EgWKAQIoAWoKEAkQChAFEAMQBA=="
        }
    }
}

/// A card in a home-feed carousel
struct ShelfItem: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let thumbnailUrl: String?
    let videoId: String?
    let browseId: String?

    init(
        title: String,
        subtitle: String,
        thumbnailUrl: String? = nil,
        videoId: String? = nil,
        browseId: String? = nil
    ) {
        self.id = videoId ?? browseId ?? UUID().uuidString
        self.title = title
        self.subtitle = subtitle
        self.thumbnailUrl = thumbnailUrl
        self.videoId = videoId
        self.browseId = browseId
    }

    func artworkAt(px: Int) -> String? {
        thumbnailUrl?.artworkAt(px: px)
    }
}

/// A shelf in the home feed
struct HomeShelf: Identifiable, Codable {
    let id: String
    let title: String
    let items: [ShelfItem]
    let subtitle: String
    let moreBrowseId: String?
    let moreParams: String?

    init(
        title: String,
        items: [ShelfItem],
        subtitle: String = "",
        moreBrowseId: String? = nil,
        moreParams: String? = nil
    ) {
        self.id = UUID().uuidString
        self.title = title
        self.items = items
        self.subtitle = subtitle
        self.moreBrowseId = moreBrowseId
        self.moreParams = moreParams
    }
}

/// A page of the Home feed
struct HomeFeed: Codable {
    let shelves: [HomeShelf]
    let continuation: String?
}

/// One server-defined group of the buttons shown on Explore
struct MoodGenreSection: Identifiable, Codable {
    let id: String
    let title: String
    let items: [BrowseItem]

    init(title: String, items: [BrowseItem]) {
        self.id = UUID().uuidString
        self.title = title
        self.items = items
    }
}

/// The signed-in Google account
struct Account: Identifiable, Codable {
    let id: String
    let name: String
    let email: String
    let thumbnailUrl: String?

    init(name: String, email: String, thumbnailUrl: String? = nil) {
        self.id = email
        self.name = name
        self.email = email
        self.thumbnailUrl = thumbnailUrl
    }
}

/// One identity the signed-in session can act as
struct AccountChannel: Identifiable, Codable {
    let id: String
    let name: String
    let subtitle: String
    let thumbnailUrl: String?
    let pageId: String?
    let dataSyncId: String?
    let activeOnWeb: Bool

    init(
        name: String,
        subtitle: String,
        thumbnailUrl: String? = nil,
        pageId: String? = nil,
        dataSyncId: String? = nil,
        activeOnWeb: Bool = false
    ) {
        self.id = pageId ?? dataSyncId ?? name
        self.name = name
        self.subtitle = subtitle
        self.thumbnailUrl = thumbnailUrl
        self.pageId = pageId
        self.dataSyncId = dataSyncId
        self.activeOnWeb = activeOnWeb
    }
}
