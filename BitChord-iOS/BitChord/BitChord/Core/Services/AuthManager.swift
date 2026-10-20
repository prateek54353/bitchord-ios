import Foundation
import Combine

/// Authentication manager for Google/YouTube Music accounts
@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentAccount: Account?
    @Published var currentChannel: AccountChannel?
    @Published var availableChannels: [AccountChannel] = []

    private let keychain: KeychainService

    init(keychain: KeychainService = KeychainService()) {
        self.keychain = keychain
    }

    func initialize() async {
        await loadSession()
    }

    // MARK: - Authentication

    func signIn() async throws {
        // TODO: Implement OAuth 2.0 flow for Google
        // This would typically use ASWebAuthenticationSession or SFSafariViewController
        // For now, we'll simulate a successful sign-in

        let account = Account(
            name: "Test User",
            email: "test@example.com",
            thumbnailUrl: nil
        )

        currentAccount = account
        isAuthenticated = true

        await saveSession()
    }

    func signOut() async {
        currentAccount = nil
        currentChannel = nil
        availableChannels.removeAll()
        isAuthenticated = false

        await clearSession()
    }

    // MARK: - Channel Management

    func selectChannel(_ channel: AccountChannel) {
        currentChannel = channel
        Task {
            await saveSession()
        }
    }

    // MARK: - Session Persistence

    private func loadSession() async {
        do {
            if let accountData = try? keychain.getData(forKey: "auth_account"),
               let account = try? JSONDecoder().decode(Account.self, from: accountData) {
                currentAccount = account
                isAuthenticated = true
            }

            if let channelData = try? keychain.getData(forKey: "auth_channel"),
               let channel = try? JSONDecoder().decode(AccountChannel.self, from: channelData) {
                currentChannel = channel
            }

            if let channelsData = try? keychain.getData(forKey: "auth_channels"),
               let channels = try? JSONDecoder().decode([AccountChannel].self, from: channelsData) {
                availableChannels = channels
            }
        } catch {
            print("Failed to load session: \(error)")
        }
    }

    private func saveSession() async {
        do {
            if let account = currentAccount {
                let accountData = try JSONEncoder().encode(account)
                try keychain.setData(accountData, forKey: "auth_account")
            }

            if let channel = currentChannel {
                let channelData = try JSONEncoder().encode(channel)
                try keychain.setData(channelData, forKey: "auth_channel")
            }

            if !availableChannels.isEmpty {
                let channelsData = try JSONEncoder().encode(availableChannels)
                try keychain.setData(channelsData, forKey: "auth_channels")
            }
        } catch {
            print("Failed to save session: \(error)")
        }
    }

    private func clearSession() async {
        try? keychain.deleteData(forKey: "auth_account")
        try? keychain.deleteData(forKey: "auth_channel")
        try? keychain.deleteData(forKey: "auth_channels")
    }
}
