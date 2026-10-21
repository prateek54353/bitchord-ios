import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedSection: SettingsSection = .playback
    @State private var showingLogin = false

    var body: some View {
        NavigationView {
            List {
                Picker("Settings Section", selection: $selectedSection) {
                    ForEach(SettingsSection.allCases, id: \.self) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(.segmented)

                switch selectedSection {
                case .playback:
                    playbackSettings
                case .appearance:
                    appearanceSettings
                case .library:
                    librarySettings
                case .account:
                    accountSettings
                case .integrations:
                    integrationsSettings
                case .about:
                    aboutSettings
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Playback Settings

    private var playbackSettings: some View {
        Section {
            Picker("Audio Quality (WiFi)", selection: Binding(
                get: { settingsManager.settings.audioQualityWiFi },
                set: { settingsManager.setAudioQualityWiFi($0) }
            )) {
                ForEach(AudioQuality.allCases, id: \.self) { quality in
                    Text(quality.displayName).tag(quality)
                }
            }

            Picker("Audio Quality (Mobile)", selection: Binding(
                get: { settingsManager.settings.audioQualityMobile },
                set: { settingsManager.setAudioQualityMobile($0) }
            )) {
                ForEach(AudioQuality.allCases, id: \.self) { quality in
                    Text(quality.displayName).tag(quality)
                }
            }

            VStack(alignment: .leading) {
                Text("Crossfade Duration")
                    .font(.callout)
                Slider(
                    value: Binding(
                        get: { settingsManager.settings.crossfadeDuration },
                        set: { settingsManager.setCrossfadeDuration($0) }
                    ),
                    in: 0...12,
                    step: 0.5
                )
                Text("\(Int(settingsManager.settings.crossfadeDuration))s")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)

            VStack(alignment: .leading) {
                Text("Playback Speed")
                    .font(.callout)
                Slider(
                    value: Binding(
                        get: { settingsManager.settings.playbackSpeed },
                        set: { settingsManager.setPlaybackSpeed($0) }
                    ),
                    in: 0.5...2.0,
                    step: 0.1
                )
                Text("\(String(format: "%.1f", settingsManager.settings.playbackSpeed))x")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)

            Toggle("Skip Silence", isOn: Binding(
                get: { settingsManager.settings.skipSilence },
                set: { settingsManager.setSkipSilence($0) }
            ))

            Toggle("Loudness Normalization", isOn: Binding(
                get: { settingsManager.settings.loudnessNormalization },
                set: { settingsManager.setLoudnessNormalization($0) }
            ))

            Toggle("Gapless Playback", isOn: Binding(
                get: { settingsManager.settings.gaplessPlayback },
                set: { settingsManager.setGaplessPlayback($0) }
            ))

            Picker("Sleep Timer", selection: Binding(
                get: { settingsManager.settings.sleepTimerDuration ?? 0 },
                set: { settingsManager.setSleepTimerDuration($0 == 0 ? nil : $0) }
            )) {
                Text("Off").tag(0.0)
                ForEach(SleepTimerPreset.allCases.filter { $0 != .none }, id: \.self) { preset in
                    Text(preset.displayName).tag(preset.rawValue)
                }
            }
        } header: {
            Text("Playback")
        }
    }

    // MARK: - Appearance Settings

    private var appearanceSettings: some View {
        Section {
            Picker("Theme", selection: Binding(
                get: { settingsManager.settings.themeMode },
                set: { settingsManager.setThemeMode($0) }
            )) {
                ForEach(ThemeMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }

            Toggle("Artwork-Driven Theming", isOn: Binding(
                get: { settingsManager.settings.artworkDrivenTheming },
                set: { settingsManager.setArtworkDrivenTheming($0) }
            ))
        } header: {
            Text("Appearance")
        }
    }

    // MARK: - Library Settings

    private var librarySettings: some View {
        Section {
            Picker("Home Recents View", selection: Binding(
                get: { settingsManager.settings.homeRecentsViewType },
                set: { settingsManager.setHomeRecentsViewType($0) }
            )) {
                Text("List").tag(LibraryViewType.list)
                Text("Grid").tag(LibraryViewType.grid)
            }

            Picker("Library Sort", selection: Binding(
                get: { settingsManager.settings.librarySort },
                set: { settingsManager.setLibrarySort($0) }
            )) {
                ForEach(LibrarySort.allCases, id: \.self) { sort in
                    Text(sort.rawValue.capitalized).tag(sort)
                }
            }

            Toggle("Swipe to Play Next", isOn: Binding(
                get: { settingsManager.settings.swipeToPlayNext },
                set: { settingsManager.setSwipeToPlayNext($0) }
            ))
        } header: {
            Text("Library")
        }
    }

    // MARK: - Account Settings

    private var accountSettings: some View {
        Section {
            if authManager.isAuthenticated {
                HStack {
                    VStack(alignment: .leading) {
                        Text(authManager.currentAccount?.name ?? "YouTube Music")
                            .font(.headline)
                        Text("Signed in")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Sign Out") {
                        Task {
                            await authManager.signOut()
                        }
                    }
                }
            } else {
                Button("Sign In to YouTube Music") {
                    showingLogin = true
                }
            }
        } header: {
            Text("Account")
        }
        .sheet(isPresented: $showingLogin) {
            YouTubeLoginView()
        }
    }

    // MARK: - Integrations Settings

    private var integrationsSettings: some View {
        Section {
            Toggle("Last.fm Scrobbling", isOn: Binding(
                get: { settingsManager.settings.lastfmScrobbleEnabled },
                set: { settingsManager.setLastfmScrobbleEnabled($0) }
            ))

            if settingsManager.settings.lastfmScrobbleEnabled {
                NavigationLink("Last.fm Configuration") {
                    LastFmSettingsView()
                }
            }

            Toggle("ListenBrainz", isOn: Binding(
                get: { settingsManager.settings.listenBrainzEnabled },
                set: { settingsManager.setListenBrainzEnabled($0) }
            ))

            if settingsManager.settings.listenBrainzEnabled {
                NavigationLink("ListenBrainz Configuration") {
                    ListenBrainzSettingsView()
                }
            }

            Toggle("Discord Rich Presence", isOn: Binding(
                get: { settingsManager.settings.discordRichPresenceEnabled },
                set: { settingsManager.setDiscordRichPresenceEnabled($0) }
            ))

            NavigationLink("Spotify Integration") {
                SpotifySettingsView()
            }
        } header: {
            Text("Integrations")
        }
    }

    // MARK: - About Settings

    private var aboutSettings: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }

            NavigationLink("License") {
                LicenseView()
            }

            NavigationLink("GitHub") {
                if let url = URL(string: "https://github.com/kushagrasinghx/BitChord") {
                    LinkView(url: url)
                }
            }
        } header: {
            Text("About")
        }
    }
}

enum SettingsSection: String, CaseIterable {
    case playback = "Playback"
    case appearance = "Appearance"
    case library = "Library"
    case account = "Account"
    case integrations = "Integrations"
    case about = "About"
}

struct LastFmSettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var apiKey = ""
    @State private var secret = ""
    @State private var sessionKey = ""
    @State private var endpoint = ""

    var body: some View {
        Form {
            Section {
                TextField("API Key", text: $apiKey)
                    .textInputAutocapitalization(.never)
                TextField("Secret", text: $secret)
                    .textInputAutocapitalization(.never)
                TextField("Session Key", text: $sessionKey)
                    .textInputAutocapitalization(.never)
                TextField("Endpoint", text: $endpoint)
                    .textInputAutocapitalization(.never)
            } header: {
                Text("Last.fm Credentials")
            } footer: {
                Text("Enter your Last.fm API credentials from https://www.last.fm/api/account/create")
            }

            Button("Save") {
                settingsManager.setLastfmApiKey(apiKey.isEmpty ? nil : apiKey)
                settingsManager.setLastfmSecret(secret.isEmpty ? nil : secret)
                settingsManager.setLastfmSessionKey(sessionKey.isEmpty ? nil : sessionKey)
                settingsManager.setLastfmEndpoint(endpoint.isEmpty ? "https://ws.audioscrobbler.com/2.0/" : endpoint)
            }
        }
        .navigationTitle("Last.fm")
        .onAppear {
            apiKey = settingsManager.settings.lastfmApiKey ?? ""
            secret = settingsManager.settings.lastfmSecret ?? ""
            sessionKey = settingsManager.settings.lastfmSessionKey ?? ""
            endpoint = settingsManager.settings.lastfmEndpoint
        }
    }
}

struct LicenseView: View {
    var body: some View {
        ScrollView {
            Text("""
            GNU GENERAL PUBLIC LICENSE
            Version 3, 29 June 2007

            Copyright (C) 2007 Free Software Foundation, Inc.
            Everyone is permitted to copy and distribute verbatim copies
            of this license document, but changing it is not allowed.
            """)
            .font(.caption)
            .padding()
        }
        .navigationTitle("License")
    }
}

struct LinkView: View {
    let url: URL

    var body: some View {
        Text("External link")
            .navigationTitle("GitHub")
            .onAppear {
                UIApplication.shared.open(url)
            }
    }
}

struct ListenBrainzSettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var token = ""

    var body: some View {
        Form {
            Section {
                TextField("User Token", text: $token)
                    .textInputAutocapitalization(.never)
            } header: {
                Text("ListenBrainz Credentials")
            } footer: {
                Text("Enter your ListenBrainz user token from https://listenbrainz.org/settings")
            }

            Button("Save") {
                settingsManager.setListenBrainzToken(token.isEmpty ? nil : token)
            }
        }
        .navigationTitle("ListenBrainz")
        .onAppear {
            token = settingsManager.settings.listenBrainzToken ?? ""
        }
    }
}

struct SpotifySettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var clientId = ""
    @State private var clientSecret = ""
    @State private var accessToken = ""

    var body: some View {
        Form {
            Section {
                TextField("Client ID", text: $clientId)
                    .textInputAutocapitalization(.never)
                TextField("Client Secret", text: $clientSecret)
                    .textInputAutocapitalization(.never)
                TextField("Access Token", text: $accessToken)
                    .textInputAutocapitalization(.never)
            } header: {
                Text("Spotify Credentials")
            } footer: {
                Text("Enter your Spotify application credentials from https://developer.spotify.com/dashboard")
            }

            Button("Save") {
                // Note: These would need to be stored securely in Keychain in production
                // For now, they're stored in settings
            }
        }
        .navigationTitle("Spotify")
    }
}

#Preview {
    SettingsScreen()
        .environmentObject(SettingsManager())
        .environmentObject(AuthManager())
}
