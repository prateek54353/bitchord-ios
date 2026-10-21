import SwiftUI

struct HomeScreen: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var playbackManager: PlaybackManager
    @EnvironmentObject var libraryManager: LibraryManager
    @EnvironmentObject var settingsManager: SettingsManager
    @ObservedObject private var repository = YTMusicRepository.shared
    @State private var showingSettings = false

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

                    // Home feed from YouTube Music
                    HomeFeedView(feed: $repository.homeFeed)
                }
                .padding(.vertical)
            }
            .background(BitChordTheme.background)
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape")
                            .foregroundColor(BitChordTheme.text)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsScreen()
            }
            .task {
                try? await repository.loadHomeFeed()
            }
        }
    }
}

struct HomeFeedView: View {
    @Binding var feed: HomeFeed

    var body: some View {
        VStack(alignment: .leading, spacing: BitChordTheme.spacingLg) {
            ForEach(feed.shelves) { shelf in
                HomeShelfView(shelf: shelf)
            }
        }
    }
}

struct HomeShelfView: View {
    let shelf: HomeShelf
    @EnvironmentObject var playbackManager: PlaybackManager

    var body: some View {
        VStack(alignment: .leading, spacing: BitChordTheme.spacingMd) {
            Text(shelf.title)
                .font(BitChordTheme.headline)
                .foregroundColor(BitChordTheme.text)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: BitChordTheme.spacingMd) {
                    ForEach(shelf.items) { item in
                        ShelfItemCard(item: item)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct ShelfItemCard: View {
    let item: ShelfItem
    @EnvironmentObject var playbackManager: PlaybackManager

    var body: some View {
        VStack(alignment: .leading, spacing: BitChordTheme.spacingXs) {
            AsyncImage(url: URL(string: item.artworkAt(px: Int(Song.cardArtPx)) ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(BitChordTheme.surfaceVariant)
            }
            .frame(width: 140, height: 140)
            .cornerRadius(BitChordTheme.radiusMd)

            Text(item.title)
                .font(BitChordTheme.callout)
                .foregroundColor(BitChordTheme.text)
                .lineLimit(2)

            if !item.subtitle.isEmpty {
                Text(item.subtitle)
                    .font(BitChordTheme.caption1)
                    .foregroundColor(BitChordTheme.textSecondary)
                    .lineLimit(1)
            }
        }
        .frame(width: 140)
        .onTapGesture {
            if let videoId = item.videoId {
                let song = Song(
                    videoId: videoId,
                    title: item.title,
                    artist: item.subtitle,
                    thumbnailUrl: item.thumbnailUrl,
                    queueTier: .context
                )
                playbackManager.play(song)
            }
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
