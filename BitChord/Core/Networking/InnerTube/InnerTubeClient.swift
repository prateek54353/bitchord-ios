// Core/Networking/InnerTube/InnerTubeClient.swift
import Foundation

enum InnerTubeEndpoint: String {
    case browse = "browse"
    case search = "search"
    case next = "next"
    case player = "player"
}

class InnerTubeClient {
    private let baseURL = "https://music.youtube.com/youtubei/v1"
    private let httpClient: HttpClient

    init(httpClient: HttpClient = HttpClient()) {
        self.httpClient = httpClient
    }

    func post<RequestPayload: Encodable, Response: Decodable>(
        endpoint: InnerTubeEndpoint,
        payload: RequestPayload
    ) async throws -> Response {
        guard let url = URL(string: "\(baseURL)/\(endpoint.rawValue)") else {
            throw URLError(.badURL)
        }

        // Encode the payload
        let encoder = JSONEncoder()
        let payloadData = try encoder.encode(payload)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = payloadData

        let data = try await httpClient.post(url: url, body: payloadData)
        let decoder = JSONDecoder()
        return try decoder.decode(Response.self, from: data)
    }
}