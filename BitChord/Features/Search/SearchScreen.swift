import SwiftUI

struct SearchScreen: View {
    @State private var searchText = ""
    @State private var selectedFilter: SearchFilter = .all
    @StateObject private var repository = YTMusicRepository.shared
    @EnvironmentObject var playbackManager: PlaybackManager

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: BitChordTheme.spacingSm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(BitChordTheme.textSecondary)

                    TextField("Search", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundColor(BitChordTheme.text)
                        .autocorrectionDisabled()
                        .onSubmit {
                            performSearch()
                        }

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(BitChordTheme.textSecondary)
                        }
                    }
                }
                .padding(BitChordTheme.spacingMd)
                .background(BitChordTheme.surface)
                .cornerRadius(BitChordTheme.radiusMd)
                .padding(.horizontal)

                // Filter picker
                if !searchText.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: BitChordTheme.spacingSm) {
                            ForEach(SearchFilter.allCases, id: \.self) { filter in
                                FilterChip(
                                    title: filter.label,
                                    isSelected: selectedFilter == filter
                                ) {
                                    selectedFilter = filter
                                    performSearch()
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, BitChordTheme.spacingXs)
                }

                // Content
                ScrollView {
                    if searchText.isEmpty {
                        SearchHistoryView()
                    } else {
                        SearchResultsView(results: repository.searchResults)
                    }
                }
            }
            .background(BitChordTheme.background)
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func performSearch() {
        guard !searchText.isEmpty else { return }
        Task {
            await repository.search(query: searchText, filter: selectedFilter)
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(BitChordTheme.callout)
                .foregroundColor(isSelected ? BitChordTheme.background : BitChordTheme.text)
                .padding(.horizontal, BitChordTheme.spacingMd)
                .padding(.vertical, BitChordTheme.spacingXs)
                .background(isSelected ? BitChordTheme.primary : BitChordTheme.surface)
                .cornerRadius(BitChordTheme.radiusSm)
        }
    }
}

struct SearchHistoryView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: BitChordTheme.spacingLg) {
            Text("Recent Searches")
                .font(BitChordTheme.headline)
                .foregroundColor(BitChordTheme.text)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: BitChordTheme.spacingSm) {
                SearchHistoryItem(query: "Beatles")
                SearchHistoryItem(query: "Jazz classics")
                SearchHistoryItem(query: "Workout music")
            }
            .padding(.horizontal)

            Text("Browse All")
                .font(BitChordTheme.headline)
                .foregroundColor(BitChordTheme.text)
                .padding(.horizontal)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: BitChordTheme.spacingMd) {
                BrowseCategoryCard(title: "Pop", color: Color(hex: "#E91E63"))
                BrowseCategoryCard(title: "Hip-Hop", color: Color(hex: "#FF9800"))
                BrowseCategoryCard(title: "Rock", color: Color(hex: "#9C27B0"))
                BrowseCategoryCard(title: "Latin", color: Color(hex: "#4CAF50"))
                BrowseCategoryCard(title: "Electronic", color: Color(hex: "#2196F3"))
                BrowseCategoryCard(title: "R&B", color: Color(hex: "#F44336"))
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

struct SearchHistoryItem: View {
    let query: String

    var body: some View {
        HStack(spacing: BitChordTheme.spacingMd) {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundColor(BitChordTheme.textSecondary)

            Text(query)
                .font(BitChordTheme.body)
                .foregroundColor(BitChordTheme.text)

            Spacer()

            Image(systemName: "xmark")
                .foregroundColor(BitChordTheme.textSecondary)
        }
        .padding(.vertical, BitChordTheme.spacingXs)
    }
}

struct BrowseCategoryCard: View {
    let title: String
    let color: Color

    var body: some View {
        ZStack {
            color
                .frame(height: 100)
                .cornerRadius(BitChordTheme.radiusMd)

            Text(title)
                .font(BitChordTheme.title3)
                .foregroundColor(.white)
                .bold()
        }
    }
}

struct SearchResultsView: View {
    let results: UiState<[SearchResult]>
    @EnvironmentObject var playbackManager: PlaybackManager

    var body: some View {
        VStack(alignment: .leading, spacing: BitChordTheme.spacingLg) {
            switch results {
            case .loading:
                ProgressView()
                    .padding()

            case .loaded(let searchResults):
                if searchResults.isEmpty {
                    Text("No results found")
                        .font(BitChordTheme.body)
                        .foregroundColor(BitChordTheme.textSecondary)
                        .padding()
                } else {
                    VStack(spacing: BitChordTheme.spacingMd) {
                        ForEach(searchResults, id: \.id) { result in
                            SearchResultRow(result: result)
                        }
                    }
                    .padding(.horizontal)
                }

            case .error(let message):
                Text(message)
                    .font(BitChordTheme.body)
                    .foregroundColor(BitChordTheme.error)
                    .padding()
            }
        }
        .padding(.vertical)
    }
}

struct SearchResultRow: View {
    let result: SearchResult
    @EnvironmentObject var playbackManager: PlaybackManager

    var body: some View {
        HStack(spacing: BitChordTheme.spacingMd) {
            AsyncImage(url: URL(string: result.artworkAt(px: 52) ?? "")) { image in
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
                Text(result.title)
                    .font(BitChordTheme.body)
                    .foregroundColor(BitChordTheme.text)

                if let subtitle = result.subtitle {
                    Text(subtitle)
                        .font(BitChordTheme.caption1)
                        .foregroundColor(BitChordTheme.textSecondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, BitChordTheme.spacingXs)
        .onTapGesture {
            if let song = result.asSong {
                playbackManager.play(song)
            }
        }
    }
}

#Preview {
    SearchScreen()
}
