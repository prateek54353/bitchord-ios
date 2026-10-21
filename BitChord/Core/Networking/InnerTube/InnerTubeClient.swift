import Foundation
import CryptoKit

/// YouTube Music InnerTube API client.
/// Handles request signing, context building, visitor data, session cookies, and authentication.
final class InnerTubeClient {
    static let shared = InnerTubeClient()

    private let httpClient: HttpClient
    private let session: URLSession

    private let musicBaseURL = "https://music.youtube.com/youtubei/v1"
    private let musicOrigin = "https://music.youtube.com"
    private let youtubeOrigin = "https://www.youtube.com"

    // Default constants matching the Android reference (Innertube.kt)
    private static let fallbackClientVersion = "1.20250101.01.00"
    private static let webRemixClientId = "67"
    private static let webUserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36"

    private var visitorData: String?
    private var clientVersion: String = InnerTubeClient.fallbackClientVersion
    private var dataSyncId: String?
    private var _isLoggedIn: Bool = false
    private var cookie: String?
    private var sapisid: String?
    private var poToken: String?
    private var currentLanguage: String = "en"
    private var currentRegion: String = "US"

    /// Whether the client has valid credentials
    var isLoggedIn: Bool {
        return _isLoggedIn
    }

    /// Set credentials from AuthManager
    func setCredentials(cookie: String?, sapisid: String?, dataSyncId: String?) {
        self.cookie = cookie
        self.sapisid = sapisid
        self.dataSyncId = dataSyncId
        self._isLoggedIn = (cookie != nil && sapisid != nil)
    }

    init(httpClient: HttpClient = HttpClient(), session: URLSession = .shared) {
        self.httpClient = httpClient
        self.session = session

        // Derive device locale
        let locale = Locale.current
        if let languageCode = locale.language.languageCode?.identifier {
            self.currentLanguage = languageCode
        }
        if let regionCode = locale.language.region?.identifier {
            self.currentRegion = regionCode
        }
    }

    // MARK: - Authentication / Credentials

    func setCredentials(cookie: String?) {
        self.cookie = cookie
        guard let cookie = cookie, !cookie.isEmpty else {
            self.sapisid = nil
            self._isLoggedIn = false
            return
        }

        self._isLoggedIn = true
        self.sapisid = parseSapisid(from: cookie)
    }

    private func parseSapisid(from cookie: String) -> String? {
        // Matches the Android lookup: SAPISID, __Secure-3PAPISID, __Secure-1PAPISID
        let parts = cookie.split(separator: ";")
        for candidate in ["SAPISID", "__Secure-3PAPISID", "__Secure-1PAPISID"] {
            for part in parts {
                let trimmed = part.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("\(candidate)=") {
                    let value = String(trimmed.dropFirst(candidate.count + 1))
                    if !value.isEmpty {
                        return value
                    }
                }
            }
        }
        return nil
    }

    func setPoToken(_ token: String?) {
        self.poToken = token
    }

    func setLocale(language: String, region: String) {
        self.currentLanguage = language
        self.currentRegion = region
    }

    // MARK: - Bootstrap & Shell Scrape

    /// Scrapes visitorData from youtube.com and live clientVersion from music.youtube.com
    func initialize() async {
        async let visitorTask: Void = fetchVisitorData()
        async let shellTask: Void = fetchShellConfig()
        _ = await (visitorTask, shellTask)
    }

    private func fetchVisitorData() async {
        guard let url = URL(string: "https://www.youtube.com/sw.js_data") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(Self.webUserAgent, forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
                  let text = String(data: data, encoding: .utf8) else {
                return
            }

            // Regex matches Android Innertube.kt: Cg[A-Za-z0-9_%-]{40,}
            let pattern = #"Cg[A-Za-z0-9_%-]{40,}"#
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range, in: text) {
                self.visitorData = String(text[range])
            }
        } catch {
            // Keep existing visitorData if network fails
        }
    }

    private func fetchShellConfig() async {
        guard let url = URL(string: musicOrigin) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(Self.webUserAgent, forHTTPHeaderField: "User-Agent")
        if let cookie = self.cookie, !cookie.isEmpty {
            request.setValue(cookie, forHTTPHeaderField: "Cookie")
        }

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
                  let html = String(data: data, encoding: .utf8) else {
                return
            }

            // Scrape INNERTUBE_CLIENT_VERSION
            if let version = extractRegexMatch(pattern: #"INNERTUBE_CLIENT_VERSION":"([^"]+)""#, from: html) {
                self.clientVersion = version
            }
            // Scrape DATASYNC_ID
            if let syncId = extractRegexMatch(pattern: #"DATASYNC_ID":"([^"]+)""#, from: html) {
                self.dataSyncId = syncId
            }
            // Fallback visitorData from shell if sw.js_data failed
            if self.visitorData == nil,
               let visitor = extractRegexMatch(pattern: #"VISITOR_DATA":"([^"]+)""#, from: html) {
                self.visitorData = visitor
            }
        } catch {
            // Silently fall back to built-in constants
        }
    }

    private func extractRegexMatch(pattern: String, from text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[range])
    }

    // MARK: - Context Construction

    private func buildContext(for client: PlayerClient? = nil) -> [String: Any] {
        let clientDict: [String: Any]
        if let client = client {
            var c: [String: Any] = [
                "clientName": client.name,
                "clientVersion": client.version,
                "hl": currentLanguage,
                "gl": currentRegion,
                "utcOffsetMinutes": 0
            ]
            if let osName = client.osName { c["osName"] = osName }
            if let osVersion = client.osVersion { c["osVersion"] = osVersion }
            if let deviceModel = client.deviceModel { c["deviceModel"] = deviceModel }
            if let platform = client.platform { c["platform"] = platform }
            if let visitorData = self.visitorData, !visitorData.isEmpty {
                c["visitorData"] = visitorData
            }
            clientDict = c
        } else {
            var c: [String: Any] = [
                "clientName": "WEB_REMIX",
                "clientVersion": clientVersion,
                "hl": currentLanguage,
                "gl": currentRegion,
                "utcOffsetMinutes": 0
            ]
            if let visitorData = self.visitorData, !visitorData.isEmpty {
                c["visitorData"] = visitorData
            }
            clientDict = c
        }

        var context: [String: Any] = [
            "client": clientDict,
            "request": [
                "useSsl": true,
                "internalExperimentFlags": []
            ]
        ]

        var user: [String: Any] = ["lockedSafetyMode": false]
        if let syncId = dataSyncId, !syncId.isEmpty {
            user["onBehalfOfUser"] = syncId
        }
        context["user"] = user

        return context
    }

    // MARK: - SAPISIDHASH Authorization

    /// Generates the standard YouTube SAPISIDHASH Authorization header
    /// Format: SAPISIDHASH <timestamp>_<sha1("$timestamp $sapisid $origin")>
    private func generateSAPISIDHash(origin: String = "https://music.youtube.com") -> String? {
        guard let sapisid = self.sapisid, !sapisid.isEmpty else { return nil }
        let timestamp = Int(Date().timeIntervalSince1970)
        let message = "\(timestamp) \(sapisid) \(origin)"
        guard let messageData = message.data(using: .utf8),
              let keyData = "SAPISIDHASH".data(using: .utf8) else {
            return nil
        }

        let hmac = HMAC<Insecure.SHA1>.authenticationCode(for: messageData, using: SymmetricKey(data: keyData))
        let hash = Data(hmac).map { String(format: "%02x", $0) }.joined()
        return "\(timestamp)_\(hash)"
    }

    // MARK: - Request Execution

    /// Standard InnerTube request (WEB_REMIX context)
    func sendRequest(endpoint: String, body: [String: Any] = [:]) async throws -> [String: Any] {
        return try await sendRequest(endpoint: endpoint, body: body, client: nil)
    }

    /// InnerTube request with an explicit client identity (used for stream resolution)
    func sendRequest(
        endpoint: String,
        body: [String: Any],
        client: PlayerClient?
    ) async throws -> [String: Any] {
        var urlString = "\(musicBaseURL)/\(endpoint)?prettyPrint=false"
        if endpoint.contains("?") {
            urlString = "\(musicBaseURL)/\(endpoint)&prettyPrint=false"
        }
        guard let url = URL(string: urlString) else {
            throw InnerTubeError.requestFailed
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Headers
        let isWebClient = client?.origin != nil || client == nil
        if isWebClient {
            request.setValue(Self.webRemixClientId, forHTTPHeaderField: "X-YouTube-Client-Name")
            request.setValue(clientVersion, forHTTPHeaderField: "X-YouTube-Client-Version")
            request.setValue(musicOrigin, forHTTPHeaderField: "X-Origin")
            request.setValue(musicOrigin, forHTTPHeaderField: "Origin")
            request.setValue("\(musicOrigin)/", forHTTPHeaderField: "Referer")
        }

        let ua = client?.userAgent ?? Self.webUserAgent
        request.setValue(ua, forHTTPHeaderField: "User-Agent")

        if let visitor = self.visitorData, !visitor.isEmpty {
            request.setValue(visitor, forHTTPHeaderField: "X-Goog-Visitor-Id")
        }

        if let cookie = self.cookie, !cookie.isEmpty {
            request.setValue(cookie, forHTTPHeaderField: "Cookie")
            if let hash = generateSAPISIDHash() {
                request.setValue("SAPISIDHASH \(hash)", forHTTPHeaderField: "Authorization")
            }
        }

        // Body construction
        var mergedBody = body
        mergedBody["context"] = buildContext(for: client)

        if let poToken = self.poToken, !poToken.isEmpty {
            mergedBody["serviceIntegrityDimensions"] = ["poToken": poToken]
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: mergedBody)

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw InnerTubeError.invalidResponse
        }

        // Error code mapping
        switch http.statusCode {
        case 200..<300:
            break
        case 401, 403:
            throw InnerTubeError.authenticationRequired
        case 429:
            throw InnerTubeError.rateLimited
        default:
            throw InnerTubeError.requestFailed
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw InnerTubeError.invalidResponse
        }

        // Opportunistically adopt visitorData if returned
        if let responseContext = json["responseContext"] as? [String: Any],
           let visitor = responseContext["visitorData"] as? String,
           !visitor.isEmpty,
           self.visitorData == nil {
            self.visitorData = visitor
        }

        return json
    }
}

/// Errors thrown by the InnerTube client layer.
/// Matches what ErrorHandler.swift expects.
enum InnerTubeError: Error {
    case requestFailed
    case invalidResponse
    case authenticationRequired
    case rateLimited
}
