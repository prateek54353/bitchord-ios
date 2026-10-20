import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var playbackManager: PlaybackManager
    @EnvironmentObject var libraryManager: LibraryManager
    @EnvironmentObject var settingsManager: SettingsManager

    var body: some View {
        ZStack {
            TabView(selection: $appState.currentTab) {
                HomeScreen()
                    .tabItem {
                        Label("Home", systemImage: AppTab.home.iconName)
                    }
                    .tag(AppTab.home)

                ExploreScreen()
                    .tabItem {
                        Label("Explore", systemImage: AppTab.explore.iconName)
                    }
                    .tag(AppTab.explore)

                LibraryScreen()
                    .tabItem {
                        Label("Library", systemImage: AppTab.library.iconName)
                    }
                    .tag(AppTab.library)

                SearchScreen()
                    .tabItem {
                        Label("Search", systemImage: AppTab.search.iconName)
                    }
                    .tag(AppTab.search)
            }
            .accentColor(BitChordTheme.primary)

            // Mini player
            if playbackManager.currentSong != nil {
                VStack {
                    Spacer()
                    MiniPlayer()
                        .padding()
                }
            }

            // Now playing sheet
            if appState.showingNowPlaying {
                NowPlayingSheet()
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }

            // Queue sheet
            if appState.showingQueue {
                QueueSheet()
                    .transition(.move(edge: .bottom))
                    .zIndex(2)
            }
        }
        .onAppear {
            appState.isInitialized = true
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(PlaybackManager())
        .environmentObject(LibraryManager())
        .environmentObject(SettingsManager())
}
