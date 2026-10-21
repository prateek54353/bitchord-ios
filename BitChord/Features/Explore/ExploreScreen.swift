import SwiftUI

struct ExploreScreen: View {
    @StateObject private var repository = YTMusicRepository.shared
    @State private var selectedItem: BrowseItem?
    @State private var showingBrowsePage = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: BitChordTheme.spacingLg) {
                    Text("Explore")
                        .font(BitChordTheme.largeTitle)
                        .foregroundColor(BitChordTheme.text)
                        .padding(.horizontal)

                    // Mood/Genre sections
                    VStack(alignment: .leading, spacing: BitChordTheme.spacingMd) {
                        Text("Moods & Genres")
                            .font(BitChordTheme.headline)
                            .foregroundColor(BitChordTheme.text)
                            .padding(.horizontal)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: BitChordTheme.spacingMd) {
                            MoodGenreCard(title: "Pop", color: Color(hex: "#E91E63"), browseId: "FEmusic_library_moods_and_genres_pop")
                            MoodGenreCard(title: "Rock", color: Color(hex: "#9C27B0"), browseId: "FEmusic_library_moods_and_genres_rock")
                            MoodGenreCard(title: "Hip-Hop", color: Color(hex: "#FF9800"), browseId: "FEmusic_library_moods_and_genres_hiphop")
                            MoodGenreCard(title: "Electronic", color: Color(hex: "#2196F3"), browseId: "FEmusic_library_moods_and_genres_electronic")
                            MoodGenreCard(title: "Country", color: Color(hex: "#4CAF50"), browseId: "FEmusic_library_moods_and_genres_country")
                            MoodGenreCard(title: "R&B", color: Color(hex: "#F44336"), browseId: "FEmusic_library_moods_and_genres_rnb")
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(BitChordTheme.background)
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingBrowsePage) {
                if let item = selectedItem {
                    BrowsePageView(item: item)
                }
            }
        }
    }
}

struct MoodGenreCard: View {
    let title: String
    let color: Color
    let browseId: String
    @StateObject private var repository = YTMusicRepository.shared
    @State private var items: [ShelfItem] = []
    @State private var loading = false

    var body: some View {
        ZStack {
            color
                .frame(height: 80)
                .cornerRadius(BitChordTheme.radiusMd)

            Text(title)
                .font(BitChordTheme.headline)
                .foregroundColor(.white)
        }
        .onTapGesture {
            Task {
                await loadBrowsePage()
            }
        }
    }

    private func loadBrowsePage() async {
        loading = true
        do {
            items = try await repository.loadBrowsePage(browseId: browseId)
        } catch {
            print("Error loading browse page: \(error)")
        }
        loading = false
    }
}

struct BrowsePageView: View {
    let item: BrowseItem
    @State private var shelves: [HomeShelf] = []
    @State private var loading = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                if loading {
                    ProgressView()
                        .padding()
                } else if shelves.isEmpty {
                    Text("No content available")
                        .font(BitChordTheme.body)
                        .foregroundColor(BitChordTheme.textSecondary)
                        .padding()
                } else {
                    VStack(alignment: .leading, spacing: BitChordTheme.spacingLg) {
                        ForEach(shelves) { shelf in
                            BrowseShelfView(shelf: shelf)
                        }
                    }
                    .padding()
                }
            }
            .background(BitChordTheme.background)
            .navigationTitle(item.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await loadContent()
        }
    }

    private func loadContent() async {
        loading = true
        do {
            let shelfItems = try await YTMusicRepository.shared.loadBrowsePage(browseId: item.browseId)
            // Convert ShelfItem array to HomeShelf
            shelves = [
                HomeShelf(
                    title: item.title,
                    items: shelfItems,
                    subtitle: item.subtitle
                )
            ]
        } catch {
            print("Error: \(error)")
        }
        loading = false
    }
}

struct BrowseShelfView: View {
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
                        BrowseItemCard(item: item)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct BrowseItemCard: View {
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
                    album: nil,
                    duration: nil,
                    artworkUrl: item.thumbnailUrl,
                    queueTier: .context
                )
                playbackManager.play(song)
            }
        }
    }
}

#Preview {
    ExploreScreen()
}
