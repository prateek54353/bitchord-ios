import Foundation
import Combine

/// Global app state management
@MainActor
class AppState: ObservableObject {
    @Published var isInitialized = false
    @Published var isOnline = true
    @Published var currentTab: AppTab = .home
    @Published var showingNowPlaying = false
    @Published var showingQueue = false
    @Published var showingMiniPlayer = false

    init() {
        // Monitor network connectivity
        setupNetworkMonitoring()
    }

    private func setupNetworkMonitoring() {
        // TODO: Implement proper network monitoring
        // For now, assume online
        isOnline = true
    }
}

/// Main app tabs
enum AppTab: String, CaseIterable {
    case home = "Home"
    case explore = "Explore"
    case library = "Library"
    case search = "Search"

    var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .explore: return "compass.fill"
        case .library: return "music.note.list"
        case .search: return "magnifyingglass"
        }
    }
}
