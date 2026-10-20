import Foundation
import CryptoKit

/// InnerTube client for YouTube Music API interactions
class InnerTubeClient {
    private let httpClient: HttpClient
    private var visitorData: String?
    private var sid: String?
    private var xsrfToken: String?
    private var apiKey: String?
    private var poToken: String?

    private let baseHost = "music.youtube.com"
    private let innertubeHost = "music.youtube.com"

    init(httpClient: HttpClient = HttpClient()) {
        self.httpClient = httpClient
    }

    // MARK: - Authentication

    func setCredentials(cookie: String?) {
        // Parse cookie to extract SID and other tokens
        if let cookie = cookie {
            parseCookie(cookie)
        }
    }

    private func parseCookie(_ cookie: String) {
        let parts = cookie.split(separator: ";")
        for part in parts {
            let trimmed = part.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("SID=") {
                sid = String(trimmed.dropFirst(4))
            }
        }
    }

    // MARK: - Initial Request

    func initialize() async throws {
        // Get visitor data
        let visitorUrl = URL(string: "https://\(baseHost)/")!
        let (data, _) = try await httpClient.data(for: URLRequest(url: visitorUrl))

        // Extract visitor data from response
        if let html = String(data: data, encoding: .utf8) {
            visitorData = extractVisitorData(from: html)
        }

        // Get Innertube config
        try await fetchInnertubeConfig()
    }

    private func extractVisitorData(from html: String) -> String? {
        // Visitor data is typically in a script tag
        let pattern = #"visitorData":"([^"]+)""#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }

        let range = NSRange(html.startIndex..., in: html)
        if let match = regex.firstMatch(in: html, range: range) {
            return (html as NSString).substring(with: match.range(at: 1))
        }

        return nil
    }

    private func fetchInnertubeConfig() async throws {
        let configUrl = URL(string: "https://\(innertubeHost)/youtubei/v1/config?key=\(apiKey ?? "")")!
        var request = URLRequest(url: configUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "context": createContext()
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await httpClient.data(for: request)

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let context = json["context"] as? [String: Any],
               let client = context["client"] as? [String: Any],
               let key = client["apiKey"] as? String {
                apiKey = key
            }
        }
    }

    // MARK: - Context Building

    private func createContext() -> [String: Any] {
        return [
            "client": [
                "clientName": "WEB_REMIX",
                "clientVersion": "1.00000002",
                "hl": "en",
                "gl": "US",
                "platform": "DESKTOP",
                "deviceMake": "",
                "deviceModel": "",
                "browserName": "Chrome",
                "browserVersion": "120.0.0.0",
                "osName": "Windows",
                "osVersion": "10.0",
                "utcOffsetMinutes": 0,
                "visitorData": visitorData ?? ""
            ],
            "request": [
                "internalExperimentFlags": [],
                "useSsl": true
            ]
        ]
    }

    // MARK: - API Requests

    func sendRequest(endpoint: String, body: [String: Any]) async throws -> [String: Any] {
        let url = URL(string: "https://\(innertubeHost)/youtubei/v1/\(endpoint)?key=\(apiKey ?? "")")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let sid = sid {
            request.setValue("SAPISIDHASH=\(generateSAPISIDHash())", forHTTPHeaderField: "Authorization")
        }

        var requestBody = body
        requestBody["context"] = createContext()

        if let poToken = poToken {
            requestBody["serviceIntegrityDimensions"] = [
                "poToken": poToken
            ]
        }

        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await httpClient.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw InnerTubeError.requestFailed
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw InnerTubeError.invalidResponse
        }

        return json
    }

    // MARK: - SAPISID Hash Generation

    private func generateSAPISIDHash() -> String {
        // SAPISIDHASH format: <timestamp>_<hash>
        let timestamp = Int(Date().timeIntervalSince1970)
        let sid = self.sid ?? ""

        let message = "\(timestamp) \(sid)"
        let key = "SAPISIDHASH"

        if let data = message.data(using: .utf8),
           let keyData = key.data(using: .utf8) {
            let hmac = HMAC<Insecure.SHA1>.authenticationCode(for: data, using: SymmetricKey(data: keyData))
            let hash = Data(hmac).base64EncodedString()
            return "\(timestamp)_\(hash)"
        }

        return ""
    }

    // MARK: - PoToken

    func setPoToken(_ token: String) {
        self.poToken = token
    }
}

enum InnerTubeError: Error {
    case requestFailed
    case invalidResponse
    case authenticationRequired
    case rateLimited
}
