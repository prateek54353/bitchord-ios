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

    // MARK: - Generic Save/Load

    private func save<T: Encodable>(_ data: T, to filename: String) async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let encoded = try encoder.encode(data)
        try encoded.write(to: fileURL(for: filename))
    }

    private func load<T: Decodable>(_ type: T.Type, from filename: String) async throws -> T {
        let data = try Data(contentsOf: fileURL(for: filename))
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }

    private func loadOrDefault<T: Decodable>(_ type: T.Type, from filename: String) async -> T {
        do {
            return try await load(type, from: filename)
        } catch {
            // File doesn't exist or is corrupted, return default value
            if type == [Song].self {
                return [] as! T
            } else if type == [BrowseItem].self {
                return [] as! T
            } else if type == [UserPlaylist].self {
                return [] as! T
            }
            fatalError("Unsupported type")
        }
    }

    // MARK: - Saved Tracks

    func saveSavedTracks(_ tracks: [Song]) async throws {
        try await save(tracks, to: "saved_tracks.json")
    }

    func loadSavedTracks() async throws -> [Song] {
        return try await load([Song].self, from: "saved_tracks.json")
    }

    // MARK: - Saved Albums

    func saveSavedAlbums(_ albums: [BrowseItem]) async throws {
        try await save(albums, to: "saved_albums.json")
    }

    func loadSavedAlbums() async throws -> [BrowseItem] {
        return try await load([BrowseItem].self, from: "saved_albums.json")
    }

    // MARK: - Saved Artists

    func saveSavedArtists(_ artists: [BrowseItem]) async throws {
        try await save(artists, to: "saved_artists.json")
    }

    func loadSavedArtists() async throws -> [BrowseItem] {
        return try await load([BrowseItem].self, from: "saved_artists.json")
    }

    // MARK: - Playlists

    func savePlaylists(_ playlists: [UserPlaylist]) async throws {
        try await save(playlists, to: "playlists.json")
    }

    func loadPlaylists() async throws -> [UserPlaylist] {
        return try await load([UserPlaylist].self, from: "playlists.json")
    }

    // MARK: - Recently Played

    func saveRecentlyPlayed(_ tracks: [Song]) async throws {
        try await save(tracks, to: "recently_played.json")
    }

    func loadRecentlyPlayed() async throws -> [Song] {
        return try await load([Song].self, from: "recently_played.json")
    }

    // MARK: - Downloads

    func saveDownloads(_ tracks: [Song]) async throws {
        try await save(tracks, to: "downloads.json")
    }

    func loadDownloads() async throws -> [Song] {
        return try await load([Song].self, from: "downloads.json")
    }

    // MARK: - Settings

    func saveSettings(_ settings: AppSettings) async throws {
        try await save(settings, to: "settings.json")
    }

    func loadSettings() async throws -> AppSettings {
        return try await load(AppSettings.self, from: "settings.json")
    }

    // MARK: - Clear All Data

    func clearAllData() async throws {
        let files = [
            "saved_tracks.json",
            "saved_albums.json",
            "saved_artists.json",
            "playlists.json",
            "recently_played.json",
            "downloads.json",
            "settings.json"
        ]

        for file in files {
            let url = fileURL(for: file)
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
        }
    }
}
