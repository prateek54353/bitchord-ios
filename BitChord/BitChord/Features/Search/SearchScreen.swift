import SwiftUI

struct SearchScreen: View {
    @State private var searchText = ""
    @State private var selectedFilter: SearchFilter = .all
    @State private var isSearching = false

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
                    } else if isSearching {
                        ProgressView()
                            .padding()
                    } else {
                        SearchResultsView(query: searchText, filter: selectedFilter)
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
        isSearching = true

        // TODO: Perform actual search
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isSearching = false
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
    let query: String
    let filter: SearchFilter

    var body: some View {
        VStack(alignment: .leading, spacing: BitChordTheme.spacingLg) {
            Text("Results for \"\(query)\"")
                .font(BitChordTheme.headline)
                .foregroundColor(BitChordTheme.text)
                .padding(.horizontal)

            // Placeholder results
            VStack(spacing: BitChordTheme.spacingMd) {
                ForEach(0..<5) { _ in
                    SearchResultRow()
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

struct SearchResultRow: View {
    var body: some View {
        HStack(spacing: BitChordTheme.spacingMd) {
            Rectangle()
                .fill(BitChordTheme.surfaceVariant)
                .frame(width: 52, height: 52)
                .cornerRadius(BitChordTheme.radiusSm)

            VStack(alignment: .leading, spacing: BitChordTheme.spacingXxs) {
                Rectangle()
                    .fill(BitChordTheme.surfaceVariant)
                    .frame(height: 16)
                    .frame(maxWidth: 200)

                Rectangle()
                    .fill(BitChordTheme.surfaceVariant)
                    .frame(height: 14)
                    .frame(maxWidth: 150)
            }

            Spacer()
        }
        .padding(.vertical, BitChordTheme.spacingXs)
    }
}

#Preview {
    SearchScreen()
}
