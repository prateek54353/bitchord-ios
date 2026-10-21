// Core/Repositories/YTMusicRepository.swift
import Foundation

@MainActor
class YTMusicRepository: ObservableObject {
    static let shared = YTMusicRepository()
    
    private let innerTubeClient: InnerTubeClient

    init(innerTubeClient: InnerTubeClient = InnerTubeClient()) {
        self.innerTubeClient = innerTubeClient
    }
    
    // MARK: - Home Feed
    func fetchHomeFeed() async throws -> [ShelfItem] {
        // The browseId for the YouTube Music Home page is "FEmusic_home"
        struct BrowsePayload: Encodable {
            let browseId: String
        }
        
        let payload = BrowsePayload(browseId: "FEmusic_home")
        
        // You'll need to create the exact Response model to match InnerTube's deeply nested JSON
        let response: YTMusicBrowseResponse = try await innerTubeClient.post(
            endpoint: .browse,
            payload: payload
        )
        
        // Parse the deeply nested InnerTube JSON into your clean App models
        return parseHomeFeed(from: response)
    }
    
    // MARK: - Player (Stream URL)
    func fetchStreamData(videoId: String) async throws -> StreamInfo {
        struct PlayerPayload: Encodable {
            let videoId: String
        }
        
        let payload = PlayerPayload(videoId: videoId)
        
        let response: YTPlayerResponse = try await innerTubeClient.post(
            endpoint: .player,
            payload: payload
        )
        
        // Extract the best audio format (usually format code 251 or 140)
        guard let format = response.streamingData.adaptiveFormats.first(where: { 
            $0.mimeType.contains("audio/") 
        }) else {
            throw NSError(domain: "YTMusicRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "No audio stream found"])
        }
        
        return StreamInfo(url: format.url, durationMs: Int(response.videoDetails.lengthSeconds) ?? 0 * 1000)
    }
    
    // Helper to traverse the InnerTube grid
    private func parseHomeFeed(from response: YTMusicBrowseResponse) -> [ShelfItem] {
        // Implementation for mapping InnerTube's specific JSON structure 
        // (sectionListRenderer, musicCarouselShelfRenderer, etc.) to your ShelfItem
        return []
    }
}