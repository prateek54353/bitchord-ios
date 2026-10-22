import Foundation

/// Manages listening statistics and history
@MainActor
class ListeningStatsManager: ObservableObject {
    static let shared = ListeningStatsManager()

    @Published var totalListeningTime: TimeInterval = 0
    @Published var songsPlayed: Int = 0
    @Published var topArtists: [ArtistStat] = []
    @Published var topSongs: [SongStat] = []

    private let localStorage: LocalStorageService
    private var currentSessionStart: Date?
    private var currentSongStart: Date?

    struct ArtistStat: Identifiable, Codable {
        let id = UUID()
        let name: String
        var playCount: Int
        var totalDuration: TimeInterval
    }

    struct SongStat: Identifiable, Codable {
        let id = UUID()
        let title: String
        let artist: String
        var playCount: Int
        var totalDuration: TimeInterval
    }

    init(localStorage: LocalStorageService = LocalStorageService()) {
        self.localStorage = localStorage
        loadStats()
    }

    // MARK: - Session Tracking

    func startSession() {
        currentSessionStart = Date()
    }

    func endSession() {
        guard let start = currentSessionStart else { return }
        let duration = Date().timeIntervalSince(start)
        totalListeningTime += duration
        currentSessionStart = nil
        saveStats()
    }

    // MARK: - Song Tracking

    func trackSongStart(_ song: Song) {
        currentSongStart = Date()
    }

    func trackSongEnd(_ song: Song, duration: TimeInterval) {
        guard let start = currentSongStart else { return }
        let actualDuration = Date().timeIntervalSince(start)

        // Only count if played for at least 30 seconds or 50% of the song
        if actualDuration >= 30 || actualDuration >= duration * 0.5 {
            songsPlayed += 1
            totalListeningTime += actualDuration

            // Update artist stats
            updateArtistStat(artist: song.artist, duration: actualDuration)

            // Update song stats
            updateSongStat(title: song.title, artist: song.artist, duration: actualDuration)

            saveStats()
        }

        currentSongStart = nil
    }

    private func updateArtistStat(artist: String, duration: TimeInterval) {
        if let index = topArtists.firstIndex(where: { $0.name == artist }) {
            topArtists[index].playCount += 1
            topArtists[index].totalDuration += duration
        } else {
            topArtists.append(ArtistStat(name: artist, playCount: 1, totalDuration: duration))
        }

        // Sort by play count
        topArtists.sort { $0.playCount > $1.playCount }

        // Keep only top 20
        if topArtists.count > 20 {
            topArtists = Array(topArtists.prefix(20))
        }
    }

    private func updateSongStat(title: String, artist: String, duration: TimeInterval) {
        if let index = topSongs.firstIndex(where: { $0.title == title && $0.artist == artist }) {
            topSongs[index].playCount += 1
            topSongs[index].totalDuration += duration
        } else {
            topSongs.append(SongStat(title: title, artist: artist, playCount: 1, totalDuration: duration))
        }

        // Sort by play count
        topSongs.sort { $0.playCount > $1.playCount }

        // Keep only top 50
        if topSongs.count > 50 {
            topSongs = Array(topSongs.prefix(50))
        }
    }

    // MARK: - Persistence

    private func saveStats() {
        let stats = StatsData(
            totalListeningTime: totalListeningTime,
            songsPlayed: songsPlayed,
            topArtists: topArtists,
            topSongs: topSongs
        )

        if let data = try? JSONEncoder().encode(stats) {
            localStorage.save(key: "listening_stats", data: data)
        }
    }

    private func loadStats() {
        guard let data = localStorage.load(key: "listening_stats"),
              let stats = try? JSONDecoder().decode(StatsData.self, from: data) else {
            return
        }

        totalListeningTime = stats.totalListeningTime
        songsPlayed = stats.songsPlayed
        topArtists = stats.topArtists
        topSongs = stats.topSongs
    }

    func resetStats() {
        totalListeningTime = 0
        songsPlayed = 0
        topArtists.removeAll()
        topSongs.removeAll()
        saveStats()
    }
}

// MARK: - Data Models

private struct StatsData: Codable {
    let totalListeningTime: TimeInterval
    let songsPlayed: Int
    let topArtists: [ListeningStatsManager.ArtistStat]
    let topSongs: [ListeningStatsManager.SongStat]
}
