// Core/Repositories/YTMusicRepository.swift
import Foundation

/// Suspend API over Innertube. Every call returns a Result so the UI can show a real error.
/// Ported from Android's YtMusicRepository.kt
class YTMusicRepository {
    static let shared = YTMusicRepository()

    private let innerTubeClient: InnerTubeClient

    // Cache for mood/genre shelves
    private var moodGenreShelfCache: [String: [HomeShelf]] = [:]
    // Cache for audio version lookups
    private var audioVersionCache: [String: Song] = [:]
    // Cache for video version lookups
    private var videoVersionCache: [String: Song?] = [:]

    private init(innerTubeClient: InnerTubeClient = .shared) {
        self.innerTubeClient = innerTubeClient
    }

    // Check if logged in
    private var isLoggedIn: Bool {
        return innerTubeClient.isLoggedIn
    }

    /// Initialize the repository (fetch visitor data and shell config)
    func initialize() async {
        await innerTubeClient.initialize()
    }

    // MARK: - Home Feed

    /// The core personalised feed
    func home() async throws -> HomeFeed {
        let response = try await innerTubeClient.sendRequest(endpoint: "browse", body: ["browseId": "FEmusic_home"])
        return InnertubeParser.parseHomeFeed(from: response)
    }

    /// Recently played is rendered independently, at the top of the Play page
    func homeRecentlyPlayed() async throws -> HomeShelf? {
        return try await recentlyPlayed()
    }

    /// Extra Play shelves are independently fetchable
    func homeSupplement(browseId: String) async throws -> [HomeShelf] {
        return try await shelvesOf(browseId: browseId)
    }

    static let homeSupplementBrowseIds = [
        "FEmusic_new_releases",
        "FEmusic_explore"
    ]

    /// More Home shelves past home()'s first page
    func moreHome(token: String) async throws -> HomeFeed {
        let response = try await innerTubeClient.sendRequest(endpoint: "browse", body: [
            "continuation": token
        ])
        let shelves = InnertubeParser.parseHomeContinuation(from: response)
        let continuationToken = InnertubeParser.extractSectionListContinuation(from: response)
        return HomeFeed(shelves: shelves, continuation: continuationToken)
    }

    // MARK: - History & Recents

    private let historyBrowseId = "FEmusic_history"
    private let recentTitle = "Recents"
    private let recentLimit = 20

    /// The account's listening history, newest first
    func history() async throws -> [Song] {
        let response = try await innerTubeClient.sendRequest(endpoint: "browse", body: ["browseId": historyBrowseId])
        return InnertubeParser.collectSongsDeep(from: response)
    }

    /// Account listening history for the Recents feed
    func recents() async throws -> [Song] {
        if innerTubeClient.isLoggedIn {
            let historySongs = try? await history()
            if let songs = historySongs, !songs.isEmpty {
                return Array(songs.prefix(recentLimit))
            }
        }
        return []
    }

    /// Recommended discovery tracks for Quick Picks
    func quickPicks(excludeSongIds: Set<String> = []) async throws -> [Song] {
        // Try to get from home feed first
        let homeRaw = try? await innerTubeClient.sendRequest(endpoint: "browse", body: ["browseId": "FEmusic_home"])
        let shelves = homeRaw != nil ? InnertubeParser.parseHome(from: homeRaw!) : []

        // 1. Direct "Quick picks" or "Mix" or "Recommendations" shelf
        let qpShelf = shelves.first { shelf in
            shelf.title.localizedCaseInsensitiveContains("quick") ||
            shelf.title.localizedCaseInsensitiveContains("pick") ||
            shelf.title.localizedCaseInsensitiveContains("mix") ||
            shelf.title.localizedCaseInsensitiveContains("recommend")
        }

        let qpSongs = qpShelf?.items.compactMap { item -> Song? in
            guard let videoId = item.videoId, !excludeSongIds.contains(videoId) else { return nil }
            return Song(
                videoId: videoId,
                title: item.title,
                artist: artistFromSubtitle(item.subtitle),
                thumbnailUrl: item.thumbnailUrl
            )
        } ?? []

        if !qpSongs.isEmpty { return qpSongs }

        // 2. All shelves on Home (excluding recent/history)
        let candidateShelves = shelves.count > 1
            ? Array(shelves.drop(1)).filter { shelf in !isHistoryShelf(shelf) }
            : shelves

        let homeShelfSongs = candidateShelves.flatMap { shelf in
            shelf.items.compactMap { item -> Song? in
                guard let videoId = item.videoId, !excludeSongIds.contains(videoId) else { return nil }
                return Song(
                    videoId: videoId,
                    title: item.title,
                    artist: artistFromSubtitle(item.subtitle),
                    thumbnailUrl: item.thumbnailUrl
                )
            }
        }.deduplicated(by: \Song.videoId)

        if !homeShelfSongs.isEmpty { return homeShelfSongs }

        // 3. Any shelf items on Home that have videoId
        let allHomeTrackSongs = shelves.flatMap { shelf in
            shelf.items.compactMap { item -> Song? in
                guard let videoId = item.videoId else { return nil }
                return Song(
                    videoId: videoId,
                    title: item.title,
                    artist: artistFromSubtitle(item.subtitle),
                    thumbnailUrl: item.thumbnailUrl
                )
            }
        }.deduplicated(by: \Song.videoId)

        let uniqueAllHome = allHomeTrackSongs.filter { !excludeSongIds.contains($0.videoId) }
        if !uniqueAllHome.isEmpty { return uniqueAllHome }

        // 4. Explore / New releases
        let explore = try? await shelvesOf(browseId: "FEmusic_new_releases")
        let exploreSongs = explore?.flatMap { shelf in
            shelf.items.compactMap { item -> Song? in
                guard let videoId = item.videoId, !excludeSongIds.contains(videoId) else { return nil }
                return Song(
                    videoId: videoId,
                    title: item.title,
                    artist: artistFromSubtitle(item.subtitle),
                    thumbnailUrl: item.thumbnailUrl
                )
            }
        }.deduplicated(by: \Song.videoId) ?? []

        if !exploreSongs.isEmpty { return exploreSongs }

        // 5. Fallback
        return allHomeTrackSongs.isEmpty ? exploreSongs : allHomeTrackSongs
    }

    private func isHistoryShelf(_ shelf: HomeShelf) -> Bool {
        shelf.title.localizedCaseInsensitiveContains("recent") ||
        shelf.title.localizedCaseInsensitiveContains("history") ||
        shelf.title.localizedCaseInsensitiveContains("listen again")
    }

    private func recentlyPlayed() async throws -> HomeShelf? {
        let ytSongs = innerTubeClient.isLoggedIn
            ? (try? await history()) ?? []
            : []

        let allSongs = ytSongs.deduplicated(by: \.videoId).prefix(recentLimit)
        guard !allSongs.isEmpty else { return nil }

        return HomeShelf(
            title: recentTitle,
            items: allSongs.map { song in
                ShelfItem(
                    title: song.title,
                    subtitle: song.artist,
                    thumbnailUrl: song.thumbnailUrl,
                    videoId: song.videoId,
                    browseId: nil
                )
            }
        )
    }

    private func shelvesOf(browseId: String) async throws -> [HomeShelf] {
        let response = try await innerTubeClient.sendRequest(endpoint: "browse", body: ["browseId": browseId])
        return InnertubeParser.parseHome(from: response)
    }

    // MARK: - Moods & Genres

    /// The server-defined mood and genre categories used by Explore
    func moodAndGenres() async throws -> [MoodGenreSection] {
        let response = try await innerTubeClient.sendRequest(endpoint: "browse", body: ["browseId": "FEmusic_moods_and_genres"])
        return InnertubeParser.parseMoodAndGenres(from: response)
    }

    /// The playlist shelves behind one mood/genre category
    func moodGenreShelves(browseId: String, params: String?) async throws -> [HomeShelf] {
        let key = "\(browseId):\(params ?? "")"
        if let cached = moodGenreShelfCache[key] {
            return cached
        }

        let response = try await innerTubeClient.sendRequest(endpoint: "browse", body: {
            var body: [String: Any] = ["browseId": browseId]
            if let params = params {
                body["params"] = params
            }
            return body
        }())
        let shelves = InnertubeParser.parseHome(from: response)
        moodGenreShelfCache[key] = shelves
        return shelves
    }

    /// A category card borrows the first real cover from the playlists it opens
    func moodGenreArtwork(browseId: String, params: String?) async throws -> String? {
        let shelves = try await moodGenreShelves(browseId: browseId, params: params)
        return shelves.flatMap { $0.items }
            .compactMap { $0.thumbnailUrl }
            .first
    }

    // MARK: - Search

    struct SearchPage {
        let rows: [SearchResult]
        let continuation: String?
    }

    /// Fetches only the first search page
    func searchPage(query: String, filter: SearchFilter, anonymous: Bool = true) async throws -> SearchPage {
        var body: [String: Any] = [
            "query": query,
            "input": query
        ]
        if let params = filter.params {
            body["params"] = params
        }
        let response = try await innerTubeClient.sendRequest(endpoint: "search", body: body)
        let page = InnertubeParser.parseSearchPage(from: response, includeVideos: filter == .videos)
        return SearchPage(
            rows: page.rows.deduplicated(by: { $0.identityKey() }),
            continuation: page.continuation
        )
    }

    /// Fetches the next page of a search
    func searchContinuation(token: String, filter: SearchFilter) async throws -> SearchPage {
        let response = try await innerTubeClient.sendRequest(endpoint: "search", body: [
            "continuation": token
        ])
        let page = InnertubeParser.parseSearchPage(from: response, includeVideos: filter == .videos)
        return SearchPage(
            rows: page.rows.deduplicated(by: { $0.identityKey() }),
            continuation: page.continuation
        )
    }

    /// Search for results (first page only)
    func search(query: String, filter: SearchFilter) async throws -> [SearchResult] {
        let page = try await searchPage(query: query, filter: filter)
        return page.rows
    }

    /// Search suggestions for typeahead
    func searchSuggestions(input: String) async throws -> [String] {
        let response = try await innerTubeClient.sendRequest(endpoint: "search", body: [
            "input": input,
            "inputType": "QUERY_SUGGESTION_TYPE_QUERY"
        ])
        return InnertubeParser.parseSearchSuggestions(from: response)
    }

    /// Live media results for the typeahead phase
    func searchTypeahead(input: String) async throws -> SearchPage {
        let response = try await innerTubeClient.sendRequest(endpoint: "search", body: [
            "query": input
        ])
        let page = InnertubeParser.parseSearchPage(from: response, includeVideos: false)
        return SearchPage(
            rows: page.rows.deduplicated(by: { $0.identityKey() }),
            continuation: page.continuation
        )
    }

    // MARK: - Browse

    /// Browse songs from a playlist, album, or library
    func browseSongs(browseId: String) async throws -> (songs: [Song], continuation: String?) {
        let response = try await innerTubeClient.sendRequest(endpoint: "browse", body: ["browseId": browseId])
        let songs = InnertubeParser.collectSongsDeep(from: response)
        let continuation = InnertubeParser.extractSectionListContinuation(from: response)
        return (songs, continuation)
    }

    /// Browse continuation for pagination
    func browseContinuation(token: String) async throws -> [Song] {
        let response = try await innerTubeClient.sendRequest(endpoint: "browse", body: ["continuation": token])
        return InnertubeParser.collectSongsDeep(from: response)
    }

    /// Get library playlists
    func libraryPlaylists() async throws -> [BrowseItem] {
        let response = try await innerTubeClient.sendRequest(endpoint: "browse", body: ["browseId": "FEmusic_library_landing"])
        return InnertubeParser.parseLibraryPlaylists(from: response)
    }

    /// Get liked music
    func likedMusic() async throws -> [Song] {
        // Try multiple browse IDs for liked music
        let browseIds = ["FEmusic_liked_videos", "LM", "VLLM"]

        for browseId in browseIds {
            do {
                let result = try await browseSongs(browseId: browseId)
                if !result.songs.isEmpty {
                    return result.songs
                }
            } catch {
                continue
            }
        }

        // Fallback: try to find liked playlist in library
        let playlists = try? await libraryPlaylists()
        let likedCard = playlists?.first { playlist in
            playlist.browseId == "VLLM" || playlist.title.localizedCaseInsensitiveContains("liked")
        }

        if let likedBrowseId = likedCard?.browseId {
            let result = try? await browseSongs(browseId: likedBrowseId)
            if let songs = result?.songs, !songs.isEmpty {
                return songs
            }
        }

        return []
    }

    // MARK: - Artist & Album

    /// Get artist page
    func getArtist(browseId: String) async throws -> (songs: [Song], albums: [BrowseItem], singles: [BrowseItem]) {
        let response = try await innerTubeClient.sendRequest(endpoint: "browse", body: ["browseId": browseId])
        return InnertubeParser.parseArtistPage(from: response)
    }

    /// Get album page
    func getAlbum(browseId: String) async throws -> (songs: [Song], metadata: [String: Any]) {
        let response = try await innerTubeClient.sendRequest(endpoint: "browse", body: ["browseId": browseId])
        let songs = InnertubeParser.collectSongsDeep(from: response)
        let metadata = InnertubeParser.parseAlbumMetadata(from: response)
        return (songs, metadata)
    }

    // MARK: - Version Resolution

    /// Find the catalogue (audio-only) release of a music-video upload
    func resolveAudio(song: Song) async throws -> Song {
        guard song.isVideo else { return song }
        if let cached = audioVersionCache[song.videoId] { return cached }

        // Search for the audio version
        let queries = [
            "\(song.title) \(song.artist)",
            song.title
        ]

        for query in queries {
            do {
                let results = try await search(query: query, filter: .songs)
                let tracks = results.compactMap { result -> Song? in
                    if case .track(let song) = result { return song }
                    return nil
                }

                // Find best match
                if let match = tracks.first(where: { track in
                    track.title.localizedCaseInsensitiveContains(song.title) &&
                    track.artist.localizedCaseInsensitiveContains(song.artist)
                }) {
                    audioVersionCache[song.videoId] = match
                    return match
                }
            } catch {
                continue
            }
        }

        // Return original if no match found
        audioVersionCache[song.videoId] = song
        return song
    }

    /// Find the video/music-video version of an audio-only track
    func resolveVideo(song: Song) async throws -> Song? {
        guard !song.isVideo else { return nil }
        if let cached = videoVersionCache[song.videoId] { return cached }

        let queries = [
            "\(song.title) \(song.artist)",
            song.title
        ]

        for query in queries {
            do {
                let results = try await search(query: query, filter: .videos)
                let tracks = results.compactMap { result -> Song? in
                    if case .track(let song) = result { return song }
                    return nil
                }

                if let match = tracks.first(where: { track in
                    track.title.localizedCaseInsensitiveContains(song.title) &&
                    track.artist.localizedCaseInsensitiveContains(song.artist)
                }) {
                    videoVersionCache[song.videoId] = match
                    return match
                }
            } catch {
                continue
            }
        }

        videoVersionCache[song.videoId] = nil
        return nil
    }

    // MARK: - Helpers

    private func artistFromSubtitle(_ subtitle: String) -> String {
        // Extract artist from subtitle (format: "Artist • Album" or just "Artist")
        let parts = subtitle.split(separator: "•", maxSplits: 1)
        return parts.first?.trimmingCharacters(in: .whitespaces) ?? subtitle
    }
}

// MARK: - Array Extensions

extension Array {
    func deduplicated<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        var seen = Set<T>()
        return filter { seen.insert($0[keyPath: keyPath]).inserted }
    }

    func deduplicated<T: Hashable>(by keyFn: (Element) -> T) -> [Element] {
        var seen = Set<T>()
        return filter { seen.insert(keyFn($0)).inserted }
    }
}

extension SearchResult {
    func identityKey() -> String {
        switch self {
        case .topTrack(let song), .track(let song):
            return "v:\(song.videoId)"
        case .browse(let item):
            return "b:\(item.browseId)"
        }
    }
}