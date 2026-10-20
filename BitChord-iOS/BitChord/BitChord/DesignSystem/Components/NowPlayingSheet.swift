import SwiftUI

struct NowPlayingSheet: View {
    @EnvironmentObject var playbackManager: PlaybackManager
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @GestureState private var dragOffset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {
            // Background
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

                Spacer()

                // Artwork
                AsyncImage(url: URL(string: playbackManager.currentSong?.artworkAt(px: Int(Song.playerArtPx)) ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .fill(BitChordTheme.surfaceVariant)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, BitChordTheme.spacingXl)
                .shadow(radius: 20)

                Spacer()

                // Track info
                VStack(spacing: BitChordTheme.spacingXs) {
                    Text(playbackManager.currentSong?.title ?? "")
                        .font(BitChordTheme.title2)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    Text(playbackManager.currentSong?.artist ?? "")
                        .font(BitChordTheme.callout)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal)

                Spacer()

                // Progress bar
                VStack(spacing: BitChordTheme.spacingXs) {
                    Slider(
                        value: Binding(
                            get: { playbackManager.currentTime },
                            set: { playbackManager.seek(to: $0) }
                        ),
                        in: 0...playbackManager.duration
                    )
                    .accentColor(.white)

                    HStack {
                        Text(formatTime(playbackManager.currentTime))
                            .font(BitChordTheme.caption2)
                            .foregroundColor(.white.opacity(0.7))

                        Spacer()

                        Text(formatTime(playbackManager.duration))
                            .font(BitChordTheme.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Controls
                HStack(spacing: BitChordTheme.spacingXl) {
                    Button(action: {
                        // Shuffle
                        playbackManager.isShuffled.toggle()
                    }) {
                        Image(systemName: playbackManager.isShuffled ? "shuffle.fill" : "shuffle")
                            .font(.title3)
                            .foregroundColor(playbackManager.isShuffled ? .white : .white.opacity(0.5))
                    }

                    Button(action: {
                        playbackManager.previous()
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }

                    Button(action: {
                        if playbackManager.isPlaying {
                            playbackManager.pause()
                        } else {
                            playbackManager.play()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(.white)
                                .frame(width: 70, height: 70)

                            Image(systemName: playbackManager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.black)
                        }
                    }

                    Button(action: {
                        playbackManager.next()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }

                    Button(action: {
                        // Repeat
                        let modes: [RepeatMode] = [.off, .all, .one]
                        if let currentIndex = modes.firstIndex(where: { $0 == playbackManager.repeatMode }) {
                            let nextIndex = (currentIndex + 1) % modes.count
                            playbackManager.repeatMode = modes[nextIndex]
                        }
                    }) {
                        Image(systemName: repeatIcon)
                            .font(.title3)
                            .foregroundColor(playbackManager.repeatMode == .off ? .white.opacity(0.5) : .white)
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Bottom controls
                HStack(spacing: BitChordTheme.spacingXl) {
                    Button(action: {}) {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Button(action: {}) {
                        Image(systemName: "quote.bubble")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Button(action: {
                        // Show queue
                        appState.showingQueue = true
                    }) {
                        Image(systemName: "list.bullet")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.bottom, BitChordTheme.spacingXl)
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

    private var repeatIcon: String {
        switch playbackManager.repeatMode {
        case .off:
            return "repeat"
        case .all:
            return "repeat"
        case .one:
            return "repeat.1"
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    NowPlayingSheet()
        .environmentObject(PlaybackManager())
        .environmentObject(AppState())
}
