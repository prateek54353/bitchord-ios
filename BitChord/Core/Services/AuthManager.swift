import Foundation
import Combine

/// Authentication manager for Google/YouTube Music accounts
@MainActor
class AuthManager: ObservableObject {

    // Shared singleton instance
    static let shared = AuthManager()

    @Published var isAuthenticated = false
    @Published var currentAccount: Account?
    @Published var currentChannel: AccountChannel?
    @Published var availableChannels: [AccountChannel] = []

    private let keychain: KeychainService
    private var visitorData: String?
    private var dataSyncId: String?
    private var _isLoggedIn: Bool = false
    private var cookie: String?
    private var sapisid: String?

    init(keychain: KeychainService = KeychainService()) {
        self.keychain = keychain
    }

    func initialize() async {
        await loadSession()
    }

    // MARK: - Authentication

    func signIn() async throws {
        // Real sign-in is handled via YouTubeLoginView
        // This is a fallback for programmatic sign-in
        throw NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Use YouTubeLoginView for sign-in"])
    }

    /// Save session from WebView login
    func saveSession(cookie: String, dataSyncId: String?) async {
        self.cookie = cookie
        self.sapisid = extractSAPISID(from: cookie)
        self.dataSyncId = dataSyncId
        self._isLoggedIn = true

        let account = Account(
            name: "YouTube Music",
            email: "",
            thumbnailUrl: nil
        )

        currentAccount = account
        isAuthenticated = true

        await saveSessionToKeychain()
    }

    private func saveSessionToKeychain() async {
        do {
            // Save cookie
            if let cookie = cookie, let cookieData = cookie.data(using: .utf8) {
                try keychain.setData(
                    cookieData,
                    forKey: "auth_cookie"
                )
            }

            // Save dataSyncId
            if let dataSyncId = dataSyncId, let dataSyncIdData = dataSyncId.data(using: .utf8) {
                try keychain.setData(
                    dataSyncIdData,
                    forKey: "auth_datasyncid"
                )
            }

            if let account = currentAccount {
                let accountData = try JSONEncoder().encode(account)
                try keychain.setData(
                    accountData,
                    forKey: "auth_account"
                )
            }

            if let channel = currentChannel {
                let channelData = try JSONEncoder().encode(channel)
                try keychain.setData(
                    channelData,
                    forKey: "auth_channel"
                )
            }

            if !availableChannels.isEmpty {
                let channelsData = try JSONEncoder().encode(
                    availableChannels
                )
                try keychain.setData(
                    channelsData,
                    forKey: "auth_channels"
                )
            }

            // Update InnerTubeClient with credentials
            InnerTubeClient.shared.setCredentials(cookie: cookie)
            InnerTubeClient.shared.setDataSyncId(dataSyncId)
        } catch {
            print("Failed to save session: \(error)")
        }
    }

    private func extractSAPISID(from cookie: String) -> String? {
        let cookies = cookie.split(separator: ";")
        for entry in cookies {
            let parts = entry.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count == 2 && (parts[0] == "SAPISID" || parts[0] == "__Secure-3PAPISID") {
                return String(parts[1])
            }
        }
        return nil
    }

    func signOut() async {
        currentAccount = nil
        currentChannel = nil
        availableChannels.removeAll()
        isAuthenticated = false
        cookie = nil
        sapisid = nil
        dataSyncId = nil
        _isLoggedIn = false

        await clearSession()
    }

    // MARK: - Channel Management

    func selectChannel(_ channel: AccountChannel) {
        currentChannel = channel

        Task {
            await saveSessionInternal()
        }
    }

    // MARK: - Session Persistence

    private func loadSession() async {
        // Load cookie and sapisid from keychain
        if let cookieData = try? keychain.getData(forKey: "auth_cookie"),
           let cookieString = String(data: cookieData, encoding: .utf8) {
            self.cookie = cookieString
            self.sapisid = extractSAPISID(from: cookieString)
        }

        if let dataSyncIdData = try? keychain.getData(forKey: "auth_datasyncid"),
           let dataSyncIdString = String(data: dataSyncIdData, encoding: .utf8) {
            self.dataSyncId = dataSyncIdString
        }

        if let accountData = try? keychain.getData(forKey: "auth_account"),
           let account = try? JSONDecoder().decode(
               Account.self,
               from: accountData
           ) {
            currentAccount = account
            isAuthenticated = true
        }

        if let channelData = try? keychain.getData(forKey: "auth_channel"),
           let channel = try? JSONDecoder().decode(
               AccountChannel.self,
               from: channelData
           ) {
            currentChannel = channel
        }

        if let channelsData = try? keychain.getData(forKey: "auth_channels"),
           let channels = try? JSONDecoder().decode(
               [AccountChannel].self,
               from: channelsData
           ) {
            availableChannels = channels
        }

        // Update InnerTubeClient
        InnerTubeClient.shared.setCredentials(cookie: cookie)
        InnerTubeClient.shared.setDataSyncId(dataSyncId)
    }

    private func saveSessionInternal() async {
        do {
            if let account = currentAccount {
                let accountData = try JSONEncoder().encode(account)
                try keychain.setData(
                    accountData,
                    forKey: "auth_account"
                )
            }

            if let channel = currentChannel {
                let channelData = try JSONEncoder().encode(channel)
                try keychain.setData(
                    channelData,
                    forKey: "auth_channel"
                )
            }

            if !availableChannels.isEmpty {
                let channelsData = try JSONEncoder().encode(
                    availableChannels
                )
                try keychain.setData(
                    channelsData,
                    forKey: "auth_channels"
                )
            }
        } catch {
            print("Failed to save session: \(error)")
        }
    }

    private func clearSession() async {
        try? keychain.deleteData(forKey: "auth_account")
        try? keychain.deleteData(forKey: "auth_channel")
        try? keychain.deleteData(forKey: "auth_channels")
        try? keychain.deleteData(forKey: "auth_cookie")
        try? keychain.deleteData(forKey: "auth_datasyncid")
    }
}
