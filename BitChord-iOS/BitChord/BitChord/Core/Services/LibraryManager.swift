import Foundation
import Combine

/// Library manager for saved tracks, albums, artists, and playlists
@MainActor
class LibraryManager: ObservableObject {
    @Published var savedTracks: [Song] = []
    @Published var savedAlbums: [BrowseItem] = []
    @Published var savedArtists: [BrowseItem] = []
    @Published var userPlaylists: [UserPlaylist] = []
    @Published var recentlyPlayed: [Song] = []
    @Published var downloads: [Song] = []

    private let localStorage: LocalStorageService

    init(localStorage: LocalStorageService = LocalStorageService()) {
        self.localStorage = localStorage
        loadLibrary()
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

    // MARK: - Recently Played

    func addToRecentlyPlayed(_ song: Song) {
        recentlyPlayed.removeAll { $0.videoId == song.videoId }
        recentlyPlayed.insert(song, at: 0)
        if recentlyPlayed.count > 50 {
            recentlyPlayed.removeLast()
        }
        saveLibrary()
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
