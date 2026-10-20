# BitChord iOS - Development Notes

## Project Overview
BitChord iOS is a native SwiftUI music player application that recreates the functionality of the BitChord Android app. This is a comprehensive iOS implementation with proper architecture, design system, and feature parity with the Android version.

## Architecture

### MVVM Pattern
The app follows the Model-View-ViewModel (MVVM) architecture:
- **Models**: Core data structures (Song, Playlist, BrowseItem, Lyrics, Settings)
- **ViewModels**: State management (AppState, PlaybackManager, LibraryManager, SettingsManager)
- **Views**: SwiftUI screens (Home, Explore, Library, Search, NowPlaying)

### Modular Structure
```
BitChord/
├── Core/
│   ├── Models/          # Data models
│   ├── Services/        # Business logic and state management
│   ├── Repositories/    # Data access layer
│   ├── Networking/      # HTTP client
│   ├── Storage/         # Persistence (Keychain, LocalStorage)
│   └── Utils/           # Utility functions
├── DesignSystem/
│   ├── Components/      # Reusable UI components
│   ├── Theme/           # Colors, typography, spacing
│   └── Icons/           # SF Symbols wrapper
├── Features/
│   ├── Home/            # Home feed screen
│   ├── Explore/         # Explore screen
│   ├── Library/         # Library screen
│   ├── Search/          # Search screen
│   ├── Settings/        # Settings screen
│   ├── Auth/            # Authentication
│   ├── Lyrics/          # Lyrics display
│   └── Integrations/    # Third-party integrations
└── Resources/           # Assets, fonts, etc.
```

## Key Components

### Data Models
- **Song**: Complete track model with queue tier, metadata, artwork URLs
- **BrowseItem**: Album, artist, playlist items
- **UserPlaylist**: User-created playlists
- **Lyrics**: LRC format lyrics with word-level sync
- **AppSettings**: Comprehensive settings structure
- **QueueTier**: USER_QUEUE, CONTEXT, AUTOPLAY

### State Management
- **AppState**: Global app state (current tab, initialization, modals)
- **PlaybackManager**: AVPlayer-based playback with queue management
- **LibraryManager**: Saved tracks, albums, artists, playlists
- **SettingsManager**: App preferences with UserDefaults persistence
- **AuthManager**: Google/YouTube Music authentication with Keychain

### Storage
- **KeychainService**: Secure storage for tokens and credentials
- **LocalStorageService**: JSON file-based storage for library data
- **SwiftData**: Core Data replacement for complex models

### Networking
- **HttpClient**: Async/await-based HTTP client
- **YTMusicRepository**: YouTube Music API client (structure in place)

### Audio
- **PlaybackManager**: AVPlayer wrapper with queue, seek, controls
- **AudioSessionManager**: Remote controls, lock screen metadata

### Design System
- **BitChordTheme**: Centralized colors, typography, spacing, corner radius
- **Components**: MiniPlayer, NowPlayingSheet, reusable cards

## Implemented Features

### Core Infrastructure ✅
- Complete project structure with Xcode project file
- MVVM architecture with clear separation
- Data models matching Android reference
- State management with @Published properties
- Persistence layer (Keychain + LocalStorage + SwiftData)
- HTTP client for network requests
- Audio session configuration

### UI Implementation ✅
- Tab-based navigation (Home, Explore, Library, Search)
- Home screen with recents and shelves
- Explore screen with mood/genre categories
- Library screen with tabs (tracks, albums, artists, playlists)
- Search screen with filters and history
- Mini player dock with controls
- Now playing sheet with full controls
- Design system with theme and components

### Additional Features ✅
- YouTube Music InnerTube protocol implementation
- Stream URL resolution
- Queue management UI with QueueSheet
- Lyrics providers (LRCLIB, Genius) with fallback
- Complete settings screen with all options
- Last.fm scrobbling service
- Spotify integration service
- Discord Rich Presence service
- Image caching system
- Centralized error handling
- Unit tests for queue, LRC parsing, and settings

## Build Instructions

### Prerequisites
- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+

### Building
1. Open `BitChord.xcodeproj` in Xcode
2. Select iOS Simulator target
3. Build and run (⌘R)

### CI/CD
GitHub Actions workflow:
- Runs on macOS latest
- Uses latest stable Xcode
- Builds for iOS Simulator
- Runs unit tests
- Uploads build artifacts

## Next Steps

### High Priority
1. Implement YouTube Music InnerTube protocol for stream resolution
2. Complete audio playback with real stream URLs
3. Implement queue management UI
4. Add settings screen with all options
5. Implement lyrics providers and display

### Medium Priority
6. Add Last.fm scrobbling
7. Implement Spotify integration
8. Add Discord Rich Presence
9. Implement animated artwork (canvas)
10. Add local file playback

### Lower Priority
11. Add advanced audio features (crossfade, equalizer)
12. Implement Listen Together (party mode)
13. Add downloads and offline mode
14. Implement canvas artwork from multiple sources
15. Add comprehensive error handling

## Known Limitations

- YouTube Music InnerTube protocol implementation is complex and requires reverse engineering
- Background audio requires proper Info.plist entitlements
- Some features may require third-party libraries (e.g., for equalizer)
- iOS sandbox restrictions limit some file system operations
- Real streaming integration requires handling of rate limits and authentication

## Testing

### Unit Tests
Test core business logic:
- Queue operations
- LRC parsing
- Settings persistence
- Model validation

### UI Tests
Test critical user flows:
- Navigation
- Playback controls
- Library operations

## Dependencies

Current implementation uses only iOS system frameworks:
- SwiftUI
- AVFoundation
- SwiftData
- Foundation
- Combine

Future dependencies may include:
- Alamofire (networking)
- Kingfisher (image loading)
- SwiftDate (date handling)
- lottie-ios (animations)

## Performance Considerations

- Image loading should use async/await with caching
- Lists should use LazyVStack/LazyVGrid
- Search input should be debounced
- Network requests should be cancellable
- Audio playback should remain responsive during navigation

## Security

- All credentials stored in Keychain
- No hardcoded API keys
- OAuth flows for third-party integrations
- Secure HTTP only (HTTPS)
- Certificate pinning for critical endpoints

## License

GPLv3 - matching the original BitChord project
