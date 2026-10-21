import Foundation

/// Discord Rich Presence service
class DiscordService {
    private var connected = false
    private var currentActivity: DiscordActivity?

    // Note: This is a simplified implementation
    // In production, you would use a proper Discord RPC library
    // Since iOS doesn't have native Discord SDK, this would typically
    // use a web socket connection to Discord's RPC

    func connect() async throws {
        // Simulate connection
        // In production, this would establish a WebSocket connection
        connected = true
    }

    func disconnect() {
        connected = false
        currentActivity = nil
    }

    func updateActivity(_ activity: DiscordActivity) async throws {
        guard connected else {
            throw DiscordError.notConnected
        }

        currentActivity = activity

        // In production, this would send the activity via WebSocket
        // For now, we'll just store it
    }

    func clearActivity() async throws {
        guard connected else {
            throw DiscordError.notConnected
        }

        currentActivity = nil
    }
}

struct DiscordActivity {
    let state: String
    let details: String
    let largeImageKey: String?
    let largeImageText: String?
    let smallImageKey: String?
    let smallImageText: String?
    let timestamps: Timestamps?
    let party: Party?
    let assets: Assets?

    struct Timestamps {
        let start: Int64?
        let end: Int64?
    }

    struct Party {
        let id: String
        let size: Int
        let max: Int
    }

    struct Assets {
        let largeImage: String?
        let largeText: String?
        let smallImage: String?
        let smallText: String?
    }
}

enum DiscordError: Error {
    case notConnected
    case connectionFailed
    case invalidPayload
}
