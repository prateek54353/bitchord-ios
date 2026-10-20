import SwiftUI

struct HomeScreen: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var playbackManager: PlaybackManager
    @EnvironmentObject var libraryManager: LibraryManager

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: BitChordTheme.spacingLg) {
                    Text("Listen Now")
                        .font(BitChordTheme.largeTitle)
                        .foregroundColor(BitChordTheme.text)
                        .padding(.horizontal)

                    // Recents shelf
                    if !libraryManager.recentlyPlayed.isEmpty {
                        VStack(alignment: .leading, spacing: BitChordTheme.spacingMd) {
                            Text("Recents")
                                .font(BitChordTheme.headline)
                                .foregroundColor(BitChordTheme.text)
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: BitChordTheme.spacingMd) {
                                    ForEach(libraryManager.recentlyPlayed.prefix(10)) { song in
                                        SongCard(song: song)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Placeholder for other shelves
                    VStack(alignment: .leading, spacing: BitChordTheme.spacingMd) {
                        Text("New Releases")
                            .font(BitChordTheme.headline)
                            .foregroundColor(BitChordTheme.text)
                            .padding(.horizontal)

                        HStack {
                            Text("Loading...")
                                .font(BitChordTheme.body)
                                .foregroundColor(BitChordTheme.textSecondary)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(BitChordTheme.background)
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct SongCard: View {
    let song: Song
    @EnvironmentObject var playbackManager: PlaybackManager

    var body: some View {
        VStack(alignment: .leading, spacing: BitChordTheme.spacingXs) {
            AsyncImage(url: URL(string: song.artworkAt(px: Int(Song.cardArtPx)) ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(BitChordTheme.surfaceVariant)
            }
            .frame(width: 140, height: 140)
            .cornerRadius(BitChordTheme.radiusMd)

            Text(song.title)
                .font(BitChordTheme.callout)
                .foregroundColor(BitChordTheme.text)
                .lineLimit(2)

            Text(song.artist)
                .font(BitChordTheme.caption1)
                .foregroundColor(BitChordTheme.textSecondary)
                .lineLimit(1)
        }
        .frame(width: 140)
        .onTapGesture {
            playbackManager.play(song)
        }
    }
}

#Preview {
    HomeScreen()
        .environmentObject(AppState())
        .environmentObject(PlaybackManager())
        .environmentObject(LibraryManager())
}
