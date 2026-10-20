import Foundation

/// HTTP client for making network requests
class HttpClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func get(url: URL, headers: [String: String]? = nil) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HttpError.invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw HttpError.httpError(httpResponse.statusCode)
        }

        return data
    }

    func post(url: URL, body: Data? = nil, headers: [String: String]? = nil) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body

        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HttpError.invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw HttpError.httpError(httpResponse.statusCode)
        }

        return data
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        return try await session.data(for: request)
    }
}

enum HttpError: Error {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case networkError(Error)
}
