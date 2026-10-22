import SwiftUI

/// Animated artwork view that adds subtle animations when playing
struct AnimatedArtworkView: View {
    let url: URL?
    let isPlaying: Bool
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0

    var body: some View {
        AsyncImage(url: url) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
        } placeholder: {
            Rectangle()
                .fill(BitChordTheme.surfaceVariant)
        }
        .scaleEffect(scale)
        .rotationEffect(.degrees(rotation))
        .animation(
            isPlaying ? .linear(duration: 20).repeatForever(autoreverses: false) : .default,
            value: rotation
        )
        .animation(
            isPlaying ? .easeInOut(duration: 2).repeatForever(autoreverses: true) : .default,
            value: scale
        )
        .onAppear {
            if isPlaying {
                startAnimation()
            }
        }
        .onChange(of: isPlaying) { newValue in
            if newValue {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
    }

    private func startAnimation() {
        withAnimation {
            rotation = 360
            scale = 1.05
        }
    }

    private func stopAnimation() {
        withAnimation {
            rotation = 0
            scale = 1.0
        }
    }
}
