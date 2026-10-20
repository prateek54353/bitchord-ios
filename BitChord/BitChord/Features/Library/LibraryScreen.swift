import SwiftUI

struct LibraryScreen: View {
    @EnvironmentObject var libraryManager: LibraryManager
    @State private var selectedTab: LibraryTab = .tracks

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                Picker("Library Tab", selection: $selectedTab) {
                    ForEach(LibraryTab.allCases, id: \.self) { tab in
                        Text(tab.displayName).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: BitChordTheme.spacingLg) {
                        switch selectedTab {
                        case .tracks:
                            if libraryManager.savedTracks.isEmpty {
                                EmptyState(
                                    icon: "music.note",
                                    title: "No saved tracks",
                                    subtitle: "Start building your library"
                                )
                            } else {
                                LazyVStack(spacing: 0) {
                                    ForEach(libraryManager.savedTracks) { song in
                                        SongRow(song: song)
                                    }
                                }
                            }

                        case .albums:
                            if libraryManager.savedAlbums.isEmpty {
                                EmptyState(
                                    icon: "square.stack",
                                    title: "No saved albums",
                                    subtitle: "Save albums to your library"
                                )
                            } else {
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: BitChordTheme.spacingLg) {
                                    ForEach(libraryManager.savedAlbums) { album in
                                        AlbumCard(album: album)
                                    }
                                }
                                .padding(.horizontal)
                            }

                        case .artists:
                            if libraryManager.savedArtists.isEmpty {
                                EmptyState(
                                    icon: "person.2",
                                    title: "No saved artists",
                                    subtitle: "Follow your favorite artists"
                                )
                            } else {
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: BitChordTheme.spacingLg) {
                                    ForEach(libraryManager.savedArtists) { artist in
                                        ArtistCard(artist: artist)
                                    }
                                }
                                .padding(.horizontal)
                            }

                        case .playlists:
                            if libraryManager.userPlaylists.isEmpty {
                                EmptyState(
                                    icon: "music.note.list",
                                    title: "No playlists",
                                    subtitle: "Create your first playlist"
                                )
                            } else {
                                LazyVStack(spacing: BitChordTheme.spacingMd) {
                                    ForEach(libraryManager.userPlaylists) { playlist in
                                        PlaylistRow(playlist: playlist)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .background(BitChordTheme.background)
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

enum LibraryTab: String, CaseIterable {
    case tracks = "Tracks"
    case albums = "Albums"
    case artists = "Artists"
    case playlists = "Playlists"

    var displayName: String {
        rawValue
    }
}

struct SongRow: View {
    let song: Song
    @EnvironmentObject var playbackManager: PlaybackManager
    @EnvironmentObject var libraryManager: LibraryManager

    var body: some View {
        HStack(spacing: BitChordTheme.spacingMd) {
            AsyncImage(url: URL(string: song.artworkAt(px: Int(Song.rowArtPx)) ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(BitChordTheme.surfaceVariant)
            }
            .frame(width: 52, height: 52)
            .cornerRadius(BitChordTheme.radiusSm)

            VStack(alignment: .leading, spacing: BitChordTheme.spacingXxs) {
                Text(song.title)
                    .font(BitChordTheme.body)
                    .foregroundColor(BitChordTheme.text)
                    .lineLimit(1)

                Text(song.artist)
                    .font(BitChordTheme.subheadline)
                    .foregroundColor(BitChordTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: {
                playbackManager.play(song)
            }) {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(BitChordTheme.primary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, BitChordTheme.spacingXs)
        .contentShape(Rectangle())
        .onTapGesture {
            playbackManager.play(song)
        }
    }
}

struct AlbumCard: View {
    let album: BrowseItem

    var body: some View {
        VStack(alignment: .leading, spacing: BitChordTheme.spacingXs) {
            AsyncImage(url: URL(string: album.artworkAt(px: Int(Song.cardArtPx)) ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(BitChordTheme.surfaceVariant)
            }
            .frame(height: 160)
            .cornerRadius(BitChordTheme.radiusMd)

            Text(album.title)
                .font(BitChordTheme.callout)
                .foregroundColor(BitChordTheme.text)
                .lineLimit(2)

            Text(album.subtitle)
                .font(BitChordTheme.caption1)
                .foregroundColor(BitChordTheme.textSecondary)
                .lineLimit(1)
        }
    }
}

struct ArtistCard: View {
    let artist: BrowseItem

    var body: some View {
        VStack(alignment: .leading, spacing: BitChordTheme.spacingXs) {
            AsyncImage(url: URL(string: artist.artworkAt(px: Int(Song.cardArtPx)) ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(BitChordTheme.surfaceVariant)
            }
            .frame(height: 160)
            .cornerRadius(BitChordTheme.radiusMd)
            .clip(Circle())

            Text(artist.title)
                .font(BitChordTheme.callout)
                .foregroundColor(BitChordTheme.text)
                .lineLimit(1)
        }
    }
}

struct PlaylistRow: View {
    let playlist: UserPlaylist

    var body: some View {
        HStack(spacing: BitChordTheme.spacingMd) {
            Rectangle()
                .fill(BitChordTheme.surfaceVariant)
                .frame(width: 52, height: 52)
                .cornerRadius(BitChordTheme.radiusSm)
                .overlay(
                    Image(systemName: "music.note.list")
                        .font(.title3)
                        .foregroundColor(BitChordTheme.textSecondary)
                )

            VStack(alignment: .leading, spacing: BitChordTheme.spacingXxs) {
                Text(playlist.title)
                    .font(BitChordTheme.body)
                    .foregroundColor(BitChordTheme.text)
                    .lineLimit(1)

                Text("\(playlist.trackCount) tracks")
                    .font(BitChordTheme.subheadline)
                    .foregroundColor(BitChordTheme.textSecondary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, BitChordTheme.spacingXs)
    }
}

struct EmptyState: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: BitChordTheme.spacingMd) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(BitChordTheme.textSecondary)

            Text(title)
                .font(BitChordTheme.headline)
                .foregroundColor(BitChordTheme.text)

            Text(subtitle)
                .font(BitChordTheme.subheadline)
                .foregroundColor(BitChordTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    LibraryScreen()
        .environmentObject(LibraryManager())
}
