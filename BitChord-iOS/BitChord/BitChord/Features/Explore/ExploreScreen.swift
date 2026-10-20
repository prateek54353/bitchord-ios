import SwiftUI

struct ExploreScreen: View {
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
                            MoodGenreCard(title: "Pop", color: Color(hex: "#E91E63"))
                            MoodGenreCard(title: "Rock", color: Color(hex: "#9C27B0"))
                            MoodGenreCard(title: "Hip-Hop", color: Color(hex: "#FF9800"))
                            MoodGenreCard(title: "Electronic", color: Color(hex: "#2196F3"))
                            MoodGenreCard(title: "Country", color: Color(hex: "#4CAF50"))
                            MoodGenreCard(title: "R&B", color: Color(hex: "#F44336"))
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(BitChordTheme.background)
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct MoodGenreCard: View {
    let title: String
    let color: Color

    var body: some View {
        ZStack {
            color
                .frame(height: 80)
                .cornerRadius(BitChordTheme.radiusMd)

            Text(title)
                .font(BitChordTheme.headline)
                .foregroundColor(.white)
        }
    }
}

#Preview {
    ExploreScreen()
}
