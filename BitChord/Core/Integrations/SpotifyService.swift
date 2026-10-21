import Foundation

/// Spotify integration service
class SpotifyService {
    private let httpClient: HttpClient
    private var accessToken: String?
    private let clientID: String
    private let clientSecret: String
    private let baseURL = "https://api.spotify.com/v1"

    init(clientID: String, clientSecret: String, httpClient: HttpClient = HttpClient()) {
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.httpClient = httpClient
    }

    // MARK: - Authentication

    func authenticate() async throws -> String {
        let authString = "\(clientID):\(clientSecret)"
        let authData = authString.data(using: .utf8)!.base64EncodedString()

        let url = URL(string: "https://accounts.spotify.com/api/token")!
        let body = "grant_type=client_credentials".data(using: .utf8)

        let headers = [
            "Authorization": "Basic \(authData)",
            "Content-Type": "application/x-www-form-urlencoded"
        ]

        let data = try await httpClient.post(url: url, body: body, headers: headers)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token = json["access_token"] as? String else {
            throw SpotifyError.authenticationFailed
        }

        accessToken = token
        return token
    }

    // MARK: - User Library

    func getUserPlaylists() async throws -> [SpotifyPlaylist] {
        guard let token = accessToken else {
            throw SpotifyError.notAuthenticated
        }

        let url = URL(string: "\(baseURL)/me/playlists")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let data = try await httpClient.get(url: url)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = json["items"] as? [[String: Any]] else {
            throw SpotifyError.invalidResponse
        }

        return items.compactMap { parsePlaylist($0) }
    }

    func getLikedSongs() async throws -> [SpotifyTrack] {
        guard let token = accessToken else {
            throw SpotifyError.notAuthenticated
        }

        let url = URL(string: "\(baseURL)/me/tracks")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let data = try await httpClient.get(url: url)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = json["items"] as? [[String: Any]] else {
            throw SpotifyError.invalidResponse
        }

        return items.compactMap { item in
            guard let track = item["track"] as? [String: Any] else { return nil }
            return parseTrack(track)
        }
    }

    // MARK: - Search

    func search(query: String, type: String = "track") async throws -> [SpotifyTrack] {
        guard let token = accessToken else {
            throw SpotifyError.notAuthenticated
        }

        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let url = URL(string: "\(baseURL)/search?q=\(encodedQuery)&type=\(type)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let data = try await httpClient.get(url: url)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tracks = json["tracks"] as? [String: Any],
              let items = tracks["items"] as? [[String: Any]] else {
            throw SpotifyError.invalidResponse
        }

        return items.compactMap { parseTrack($0) }
    }

    // MARK: - Parsing

    private func parsePlaylist(_ dict: [String: Any]) -> SpotifyPlaylist? {
        guard let id = dict["id"] as? String,
              let name = dict["name"] as? String else {
            return nil
        }

        let images = dict["images"] as? [[String: Any]]
        let imageUrl = images?.first?["url"] as? String

        return SpotifyPlaylist(
            id: id,
            name: name,
            imageUrl: imageUrl
        )
    }

    private func parseTrack(_ dict: [String: Any]) -> SpotifyTrack? {
        guard let id = dict["id"] as? String,
              let name = dict["name"] as? String,
              let album = dict["album"] as? [String: Any],
              let artists = album["artists"] as? [[String: Any]],
              let firstArtist = artists.first,
              let artistName = firstArtist["name"] as? String else {
            return nil
        }

        let images = album["images"] as? [[String: Any]]
        let imageUrl = images?.first?["url"] as? String

        return SpotifyTrack(
            id: id,
            name: name,
            artist: artistName,
            album: album["name"] as? String,
            imageUrl: imageUrl
        )
    }
}

// MARK: - Models

struct SpotifyPlaylist {
    let id: String
    let name: String
    let imageUrl: String?
}

struct SpotifyTrack {
    let id: String
    let name: String
    let artist: String
    let album: String?
    let imageUrl: String?
}

enum SpotifyError: Error {
    case notAuthenticated
    case authenticationFailed
    case invalidResponse
}
