import SwiftUI

struct MiniPlayer: View {
    @EnvironmentObject var playbackManager: PlaybackManager
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: BitChordTheme.spacingMd) {
            // Artwork
            AsyncImage(url: URL(string: playbackManager.currentSong?.artworkAt(px: Int(Song.rowArtPx)) ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(BitChordTheme.surfaceVariant)
            }
            .frame(width: 48, height: 48)
            .cornerRadius(BitChordTheme.radiusSm)

            // Track info
            VStack(alignment: .leading, spacing: BitChordTheme.spacingXxs) {
                Text(playbackManager.currentSong?.title ?? "")
                    .font(BitChordTheme.callout)
                    .foregroundColor(BitChordTheme.text)
                    .lineLimit(1)

                Text(playbackManager.currentSong?.artist ?? "")
                    .font(BitChordTheme.caption1)
                    .foregroundColor(BitChordTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            // Controls
            HStack(spacing: BitChordTheme.spacingLg) {
                Button(action: {
                    playbackManager.previous()
                }) {
                    Image(systemName: "backward.fill")
                        .font(.title3)
                        .foregroundColor(BitChordTheme.text)
                }

                Button(action: {
                    if playbackManager.isPlaying {
                        playbackManager.pause()
                    } else {
                        playbackManager.play()
                    }
                }) {
                    Image(systemName: playbackManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .foregroundColor(BitChordTheme.text)
                }

                Button(action: {
                    playbackManager.next()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.title3)
                        .foregroundColor(BitChordTheme.text)
                }
            }

            // Expand button
            Button(action: {
                withAnimation {
                    appState.showingNowPlaying = true
                }
            }) {
                Image(systemName: "chevron.up")
                    .font(.title3)
                    .foregroundColor(BitChordTheme.textSecondary)
            }
        }
        .padding()
        .background(BitChordTheme.surface)
        .cornerRadius(BitChordTheme.radiusLg)
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        .onTapGesture {
            withAnimation {
                appState.showingNowPlaying = true
            }
        }
    }
}

#Preview {
    MiniPlayer()
        .environmentObject(PlaybackManager())
        .environmentObject(AppState())
}
