import SwiftUI

struct QueueSheet: View {
    @EnvironmentObject var playbackManager: PlaybackManager
    @Environment(\.dismiss) private var dismiss
    @GestureState private var dragOffset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Handle bar
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 40, height: 4)
                    .cornerRadius(2)
                    .padding(.top, BitChordTheme.spacingSm)
                    .onTapGesture {
                        dismiss()
                    }

                // Header
                HStack {
                    Text("Queue")
                        .font(BitChordTheme.title3)
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: {
                        playbackManager.clearQueue()
                    }) {
                        Text("Clear")
                            .font(BitChordTheme.callout)
                            .foregroundColor(BitChordTheme.primary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, BitChordTheme.spacingMd)

                Divider()
                    .background(Color.white.opacity(0.1))

                // Queue list
                if playbackManager.queue.isEmpty {
                    VStack(spacing: BitChordTheme.spacingMd) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.3))

                        Text("Queue is empty")
                            .font(BitChordTheme.headline)
                            .foregroundColor(.white.opacity(0.5))

                        Text("Add songs to your queue")
                            .font(BitChordTheme.subheadline)
                            .foregroundColor(.white.opacity(0.3))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(playbackManager.queue.enumerated()), id: \.element.id) { index, song in
                                QueueRow(
                                    song: song,
                                    isPlaying: index == playbackManager.queueIndex,
                                    index: index
                                )
                            }
                        }
                    }
                }
            }
        }
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    if value.translation.height > 0 {
                        state = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 200 {
                        dismiss()
                    }
                }
        )
    }
}

struct QueueRow: View {
    let song: Song
    let isPlaying: Bool
    let index: Int
    @EnvironmentObject var playbackManager: PlaybackManager

    var body: some View {
        HStack(spacing: BitChordTheme.spacingMd) {
            // Queue number or playing indicator
            ZStack {
                if isPlaying {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.callout)
                        .foregroundColor(BitChordTheme.primary)
                } else {
                    Text("\(index + 1)")
                        .font(BitChordTheme.callout)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .frame(width: 24)

            // Artwork
            AsyncImage(url: URL(string: song.artworkAt(px: Int(Song.rowArtPx)) ?? "")) { image in
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
                Text(song.title)
                    .font(BitChordTheme.body)
                    .foregroundColor(isPlaying ? BitChordTheme.primary : .white)
                    .lineLimit(1)

                Text(song.artist)
                    .font(BitChordTheme.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }

            Spacer()

            // Remove button
            Button(action: {
                playbackManager.removeFromQueue(at: index)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, BitChordTheme.spacingXs)
        .contentShape(Rectangle())
        .onTapGesture {
            playbackManager.play(at: index)
        }
    }
}

#Preview {
    QueueSheet()
        .environmentObject(PlaybackManager())
}
