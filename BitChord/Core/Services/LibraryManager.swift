import Foundation
import Combine

/// Library manager for saved tracks, albums, artists, and playlists
/// Ported from Android's LocalMediaRepository.kt
@MainActor
class LibraryManager: ObservableObject {
    @Published var savedTracks: [Song] = []
    @Published var savedAlbums: [BrowseItem] = []
    @Published var savedArtists: [BrowseItem] = []
    @Published var userPlaylists: [UserPlaylist] = []
    @Published var recentlyPlayed: [Song] = []
    @Published var downloads: [Song] = []

    private let localStorage: LocalStorageService
    private let ytMusicRepository: YTMusicRepository

    init(
        localStorage: LocalStorageService = LocalStorageService(),
        ytMusicRepository: YTMusicRepository? = nil
    ) {
        self.localStorage = localStorage
        self.ytMusicRepository = ytMusicRepository ?? YTMusicRepository.shared
        loadLibrary()
    }

    // MARK: - Sync with YouTube Music

    /// Sync local library with YouTube Music library (requires authentication)
    func syncWithYouTubeMusic() async throws {
        // Fetch liked music from YouTube Music
        let likedSongs = try await ytMusicRepository.likedMusic()

        // Update saved tracks
        savedTracks = likedSongs
        try await localStorage.saveSavedTracks(savedTracks)

        // Fetch library playlists
        let libraryPlaylists = try await ytMusicRepository.libraryPlaylists()

        // Update saved albums/artists from library
        for item in libraryPlaylists {
            if item.type == .album {
                if !savedAlbums.contains(where: { $0.browseId == item.browseId }) {
                    savedAlbums.append(item)
                }
            } else if item.type == .artist {
                if !savedArtists.contains(where: { $0.browseId == item.browseId }) {
                    savedArtists.append(item)
                }
            }
        }

        try await localStorage.saveSavedAlbums(savedAlbums)
        try await localStorage.saveSavedArtists(savedArtists)
    }

    // MARK: - Saved Tracks

    func saveTrack(_ song: Song) {
        if !savedTracks.contains(where: { $0.videoId == song.videoId }) {
            savedTracks.append(song)
            saveLibrary()
        }
    }

    func removeTrack(_ song: Song) {
        savedTracks.removeAll { $0.videoId == song.videoId }
        saveLibrary()
    }

    func isTrackSaved(_ song: Song) -> Bool {
        savedTracks.contains { $0.videoId == song.videoId }
    }

    func toggleTrackSaved(_ song: Song) {
        if isTrackSaved(song) {
            removeTrack(song)
        } else {
            saveTrack(song)
        }
    }

    // MARK: - Saved Albums

    func saveAlbum(_ album: BrowseItem) {
        if !savedAlbums.contains(where: { $0.browseId == album.browseId }) {
            savedAlbums.append(album)
            saveLibrary()
        }
    }

    func removeAlbum(_ album: BrowseItem) {
        savedAlbums.removeAll { $0.browseId == album.browseId }
        saveLibrary()
    }

    func isAlbumSaved(_ album: BrowseItem) -> Bool {
        savedAlbums.contains { $0.browseId == album.browseId }
    }

    func toggleAlbumSaved(_ album: BrowseItem) {
        if isAlbumSaved(album) {
            removeAlbum(album)
        } else {
            saveAlbum(album)
        }
    }

    // MARK: - Saved Artists

    func saveArtist(_ artist: BrowseItem) {
        if !savedArtists.contains(where: { $0.browseId == artist.browseId }) {
            savedArtists.append(artist)
            saveLibrary()
        }
    }

    func removeArtist(_ artist: BrowseItem) {
        savedArtists.removeAll { $0.browseId == artist.browseId }
        saveLibrary()
    }

    func isArtistSaved(_ artist: BrowseItem) -> Bool {
        savedArtists.contains { $0.browseId == artist.browseId }
    }

    func toggleArtistSaved(_ artist: BrowseItem) {
        if isArtistSaved(artist) {
            removeArtist(artist)
        } else {
            saveArtist(artist)
        }
    }

    // MARK: - Playlists

    func createPlaylist(title: String, description: String? = nil) -> UserPlaylist {
        let playlist = UserPlaylist(
            playlistId: UUID().uuidString,
            title: title,
            description: description
        )
        userPlaylists.append(playlist)
        saveLibrary()
        return playlist
    }

    func deletePlaylist(_ playlist: UserPlaylist) {
        userPlaylists.removeAll { $0.playlistId == playlist.playlistId }
        saveLibrary()
    }

    func updatePlaylist(_ playlist: UserPlaylist) {
        if let index = userPlaylists.firstIndex(where: { $0.playlistId == playlist.playlistId }) {
            userPlaylists[index] = playlist
            saveLibrary()
        }
    }

    func pinPlaylist(_ playlist: UserPlaylist) {
        if let index = userPlaylists.firstIndex(where: { $0.playlistId == playlist.playlistId }) {
            userPlaylists[index].isPinned = true
            saveLibrary()
        }
    }

    func unpinPlaylist(_ playlist: UserPlaylist) {
        if let index = userPlaylists.firstIndex(where: { $0.playlistId == playlist.playlistId }) {
            userPlaylists[index].isPinned = false
            saveLibrary()
        }
    }

    func togglePlaylistPinned(_ playlist: UserPlaylist) {
        if let index = userPlaylists.firstIndex(where: { $0.playlistId == playlist.playlistId }) {
            userPlaylists[index].isPinned.toggle()
            saveLibrary()
        }
    }

    // MARK: - Playlist Song Management

    func addSongToPlaylist(_ song: Song, playlist: UserPlaylist) {
        if let index = userPlaylists.firstIndex(where: { $0.playlistId == playlist.playlistId }) {
            if !userPlaylists[index].songs.contains(where: { $0.videoId == song.videoId }) {
                userPlaylists[index].songs.append(song)
                saveLibrary()
            }
        }
    }

    func removeSongFromPlaylist(_ song: Song, playlist: UserPlaylist) {
        if let index = userPlaylists.firstIndex(where: { $0.playlistId == playlist.playlistId }) {
            userPlaylists[index].songs.removeAll { $0.videoId == song.videoId }
            saveLibrary()
        }
    }

    func moveSongInPlaylist(_ song: Song, from fromIndex: Int, to toIndex: Int, playlist: UserPlaylist) {
        if let index = userPlaylists.firstIndex(where: { $0.playlistId == playlist.playlistId }) {
            guard fromIndex < userPlaylists[index].songs.count,
                  toIndex < userPlaylists[index].songs.count else { return }

            let song = userPlaylists[index].songs.remove(at: fromIndex)
            userPlaylists[index].songs.insert(song, at: toIndex)
            saveLibrary()
        }
    }

    func isSongInPlaylist(_ song: Song, playlist: UserPlaylist) -> Bool {
        guard let playlist = userPlaylists.first(where: { $0.playlistId == playlist.playlistId }) else {
            return false
        }
        return playlist.songs.contains { $0.videoId == song.videoId }
    }

    // MARK: - Recently Played

    func addToRecentlyPlayed(_ song: Song) {
        recentlyPlayed.removeAll { $0.videoId == song.videoId }
        recentlyPlayed.insert(song, at: 0)
        if recentlyPlayed.count > 50 {
            recentlyPlayed.removeLast()
        }
        saveLibrary()
    }

    func clearRecentlyPlayed() {
        recentlyPlayed.removeAll()
        saveLibrary()
    }

    // MARK: - Downloads

    func markAsDownloaded(_ song: Song) {
        if !downloads.contains(where: { $0.videoId == song.videoId }) {
            downloads.append(song)
            saveLibrary()
        }
    }

    func removeDownload(_ song: Song) {
        downloads.removeAll { $0.videoId == song.videoId }
        saveLibrary()
    }

    func isDownloaded(_ song: Song) -> Bool {
        downloads.contains { $0.videoId == song.videoId }
    }

    func clearDownloads() {
        downloads.removeAll()
        saveLibrary()
    }

    // MARK: - Search Library

    func searchTracks(query: String) -> [Song] {
        guard !query.isEmpty else { return savedTracks }
        let lowerQuery = query.lowercased()
        return savedTracks.filter { song in
            song.title.lowercased().contains(lowerQuery) ||
            song.artist.lowercased().contains(lowerQuery) ||
            song.albumName?.lowercased().contains(lowerQuery) == true
        }
    }

    func searchAlbums(query: String) -> [BrowseItem] {
        guard !query.isEmpty else { return savedAlbums }
        let lowerQuery = query.lowercased()
        return savedAlbums.filter { album in
            album.title.lowercased().contains(lowerQuery) ||
            album.subtitle.lowercased().contains(lowerQuery)
        }
    }

    func searchArtists(query: String) -> [BrowseItem] {
        guard !query.isEmpty else { return savedArtists }
        let lowerQuery = query.lowercased()
        return savedArtists.filter { artist in
            artist.title.lowercased().contains(lowerQuery) ||
            artist.subtitle.lowercased().contains(lowerQuery)
        }
    }

    func searchPlaylists(query: String) -> [UserPlaylist] {
        guard !query.isEmpty else { return userPlaylists }
        let lowerQuery = query.lowercased()
        return userPlaylists.filter { playlist in
            playlist.title.lowercased().contains(lowerQuery) ||
            playlist.description?.lowercased().contains(lowerQuery) == true
        }
    }

    // MARK: - Statistics

    var totalTracks: Int {
        savedTracks.count
    }

    var totalAlbums: Int {
        savedAlbums.count
    }

    var totalArtists: Int {
        savedArtists.count
    }

    var totalPlaylists: Int {
        userPlaylists.count
    }

    var totalDownloads: Int {
        downloads.count
    }

    // MARK: - Persistence

    private func loadLibrary() {
        Task {
            do {
                savedTracks = try await localStorage.loadSavedTracks()
                savedAlbums = try await localStorage.loadSavedAlbums()
                savedArtists = try await localStorage.loadSavedArtists()
                userPlaylists = try await localStorage.loadPlaylists()
                recentlyPlayed = try await localStorage.loadRecentlyPlayed()
                downloads = try await localStorage.loadDownloads()
            } catch {
                print("Failed to load library: \(error)")
            }
        }
    }

    private func saveLibrary() {
        Task {
            do {
                try await localStorage.saveSavedTracks(savedTracks)
                try await localStorage.saveSavedAlbums(savedAlbums)
                try await localStorage.saveSavedArtists(savedArtists)
                try await localStorage.savePlaylists(userPlaylists)
                try await localStorage.saveRecentlyPlayed(recentlyPlayed)
                try await localStorage.saveDownloads(downloads)
            } catch {
                print("Failed to save library: \(error)")
            }
        }
    }
}
