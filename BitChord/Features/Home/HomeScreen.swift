import SwiftUI

struct HomeScreen: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var playbackManager: PlaybackManager
    @EnvironmentObject var libraryManager: LibraryManager
    @StateObject private var repository = YTMusicRepository.shared

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
                    HomeFeedView(feed: repository.homeFeed)
                }
                .padding(.vertical)
            }
            .background(BitChordTheme.background)
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await repository.loadHomeFeed()
            }
        }
    }
}

struct HomeFeedView: View {
    let feed: UiState<HomeFeed>

    var body: some View {
        switch feed {
        case .loading:
            VStack(alignment: .leading, spacing: BitChordTheme.spacingMd) {
                Text("New Releases")
                    .font(BitChordTheme.headline)
                    .foregroundColor(BitChordTheme.text)
                    .padding(.horizontal)

                HStack {
                    ProgressView()
                        .tint(BitChordTheme.primary)
                    Text("Loading...")
                        .font(BitChordTheme.body)
                        .foregroundColor(BitChordTheme.textSecondary)
                }
                .padding(.horizontal)
            }

        case .loaded(let homeFeed):
            VStack(alignment: .leading, spacing: BitChordTheme.spacingLg) {
                ForEach(homeFeed.shelves, id: \.title) { shelf in
                    ShelfView(shelf: shelf)
                }
            }

        case .error(let message):
            VStack(alignment: .leading, spacing: BitChordTheme.spacingMd) {
                Text("New Releases")
                    .font(BitChordTheme.headline)
                    .foregroundColor(BitChordTheme.text)
                    .padding(.horizontal)

                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(BitChordTheme.error)
                    Text(message)
                        .font(BitChordTheme.body)
                        .foregroundColor(BitChordTheme.textSecondary)
                }
                .padding(.horizontal)
            }
        }
    }
}

struct ShelfView: View {
    let shelf: ShelfItem
    @EnvironmentObject var playbackManager: PlaybackManager

    var body: some View {
        VStack(alignment: .leading, spacing: BitChordTheme.spacingMd) {
            Text(shelf.title)
                .font(BitChordTheme.headline)
                .foregroundColor(BitChordTheme.text)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: BitChordTheme.spacingMd) {
                    ForEach(shelf.items, id: \.id) { item in
                        BrowseItemCard(item: item)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct BrowseItemCard: View {
    let item: BrowseItem
    @EnvironmentObject var playbackManager: PlaybackManager

    var body: some View {
        VStack(alignment: .leading, spacing: BitChordTheme.spacingXs) {
            AsyncImage(url: URL(string: item.artworkAt(px: Int(BrowseItem.cardArtPx)) ?? "")) { image in
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

            if let subtitle = item.subtitle {
                Text(subtitle)
                    .font(BitChordTheme.caption1)
                    .foregroundColor(BitChordTheme.textSecondary)
                    .lineLimit(1)
            }
        }
        .frame(width: 140)
        .onTapGesture {
            if let song = item.asSong {
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
