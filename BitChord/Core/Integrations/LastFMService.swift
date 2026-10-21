import Foundation
import CryptoKit
/// Last.fm scrobbling service
class LastFMService {
    private let httpClient: HttpClient
    private var apiKey: String
    private var secret: String
    private var sessionKey: String?
    private let baseURL = "https://ws.audioscrobbler.com/2.0/"

    init(apiKey: String, secret: String, sessionKey: String? = nil, httpClient: HttpClient = HttpClient()) {
        self.apiKey = apiKey
        self.secret = secret
        self.sessionKey = sessionKey
        self.httpClient = httpClient
    }

    // MARK: - Authentication

    func authenticate(username: String, password: String) async throws -> String {
        let token = md5Hash("\(md5Hash(username))\(md5Hash(password))")

        let params = [
            "method": "auth.getMobileSession",
            "username": username,
            "authToken": token,
            "api_key": apiKey,
            "api_sig": generateSignature([
                "method": "auth.getMobileSession",
                "username": username,
                "authToken": token,
                "api_key": apiKey
            ])
        ]

        let url = URL(string: "\(baseURL)?\(params.queryString)")!
        let data = try await httpClient.get(url: url)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let session = json["session"] as? [String: Any],
              let key = session["key"] as? String else {
            throw LastFMError.authenticationFailed
        }

        sessionKey = key
        return key
    }

    // MARK: - Scrobbling

    func scrobble(track: Song, timestamp: TimeInterval, duration: TimeInterval? = nil) async throws {
        guard let sessionKey = sessionKey else {
            throw LastFMError.notAuthenticated
        }

        var params: [String: String] = [
            "method": "track.scrobble",
            "artist": track.artist,
            "track": track.title,
            "timestamp": String(Int(timestamp)),
            "api_key": apiKey,
            "sk": sessionKey
        ]

        if let album = track.albumName {
            params["album"] = album
        }

        if let duration = duration {
            params["duration"] = String(Int(duration))
        }

        params["api_sig"] = generateSignature(params)

        let url = URL(string: "\(baseURL)?\(params.queryString)")!
        _ = try await httpClient.get(url: url)
    }

    // MARK: - Now Playing

    func updateNowPlaying(track: Song, duration: TimeInterval? = nil) async throws {
        guard let sessionKey = sessionKey else {
            throw LastFMError.notAuthenticated
        }

        var params: [String: String] = [
            "method": "track.updateNowPlaying",
            "artist": track.artist,
            "track": track.title,
            "api_key": apiKey,
            "sk": sessionKey
        ]

        if let album = track.albumName {
            params["album"] = album
        }

        if let duration = duration {
            params["duration"] = String(Int(duration))
        }

        params["api_sig"] = generateSignature(params)

        let url = URL(string: "\(baseURL)?\(params.queryString)")!
        _ = try await httpClient.get(url: url)
    }

    // MARK: - Utilities

    private func generateSignature(_ params: [String: String]) -> String {
        let sorted = params.sorted { $0.key < $1.key }
        let signatureString = sorted.map { "\($0.key)\($0.value)" }.joined() + secret
        return md5Hash(signatureString)
    }

    private func md5Hash(_ string: String) -> String {
        let data = string.data(using: .utf8)!
        let hash = Insecure.MD5.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

enum LastFMError: Error {
    case notAuthenticated
    case authenticationFailed
    case invalidResponse
}

extension Dictionary where Key == String, Value == String {
    var queryString: String {
        return map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
    }
}
