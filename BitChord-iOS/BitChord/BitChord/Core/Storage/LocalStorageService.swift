import Foundation

/// Local storage service for persisting library data
class LocalStorageService {
    private let fileManager = FileManager.default
    private let documentsURL: URL

    init() {
        documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    private func fileURL(for filename: String) -> URL {
        documentsURL.appendingPathComponent(filename)
    }

    // MARK: - Saved Tracks

    func saveSavedTracks(_ tracks: [Song]) async throws {
        let data = try JSONEncoder().encode(tracks)
        try data.write(to: fileURL(for: "saved_tracks.json"))
    }

    func loadSavedTracks() async throws -> [Song] {
        let data = try Data(contentsOf: fileURL(for: "saved_tracks.json"))
        return try JSONDecoder().decode([Song].self, from: data)
    }

    // MARK: - Saved Albums

    func saveSavedAlbums(_ albums: [BrowseItem]) async throws {
        let data = try JSONEncoder().encode(albums)
        try data.write(to: fileURL(for: "saved_albums.json"))
    }

    func loadSavedAlbums() async throws -> [BrowseItem] {
        let data = try Data(contentsOf: fileURL(for: "saved_albums.json"))
        return try JSONDecoder().decode([BrowseItem].self, from: data)
    }

    // MARK: - Saved Artists

    func saveSavedArtists(_ artists: [BrowseItem]) async throws {
        let data = try JSONEncoder().encode(artists)
        try data.write(to: fileURL(for: "saved_artists.json"))
    }

    func loadSavedArtists() async throws -> [BrowseItem] {
        let data = try Data(contentsOf: fileURL(for: "saved_artists.json"))
        return try JSONDecoder().decode([BrowseItem].self, from: data)
    }

    // MARK: - Playlists

    func savePlaylists(_ playlists: [UserPlaylist]) async throws {
        let data = try JSONEncoder().encode(playlists)
        try data.write(to: fileURL(for: "playlists.json"))
    }

    func loadPlaylists() async throws -> [UserPlaylist] {
        let data = try Data(contentsOf: fileURL(for: "playlists.json"))
        return try JSONDecoder().decode([UserPlaylist].self, from: data)
    }

    // MARK: - Recently Played

    func saveRecentlyPlayed(_ tracks: [Song]) async throws {
        let data = try JSONEncoder().encode(tracks)
        try data.write(to: fileURL(for: "recently_played.json"))
    }

    func loadRecentlyPlayed() async throws -> [Song] {
        let data = try Data(contentsOf: fileURL(for: "recently_played.json"))
        return try JSONDecoder().decode([Song].self, from: data)
    }

    // MARK: - Downloads

    func saveDownloads(_ tracks: [Song]) async throws {
        let data = try JSONEncoder().encode(tracks)
        try data.write(to: fileURL(for: "downloads.json"))
    }

    func loadDownloads() async throws -> [Song] {
        let data = try Data(contentsOf: fileURL(for: "downloads.json"))
        return try JSONDecoder().decode([Song].self, from: data)
    }
}
