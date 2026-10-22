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
- **InnerTubeClient**: YouTube Music InnerTube API client with SAPISIDHASH auth
- **YTMusicRepository**: Complete YouTube Music API implementation
- **StreamResolver**: Multi-client stream URL resolution

### Audio
- **PlaybackManager**: AVPlayer wrapper with queue, seek, controls, lock screen
- **AudioSessionManager**: Remote controls, lock screen metadata

### Design System
- **BitChordTheme**: Centralized colors, typography, spacing, corner radius
- **Components**: MiniPlayer, NowPlayingSheet, QueueSheet, reusable cards

## Implementation Status

### Core Infrastructure ✅ COMPLETE
- Complete project structure with Xcode project file
- MVVM architecture with clear separation
- Data models matching Android reference
- State management with @Published properties
- Persistence layer (Keychain + LocalStorage)
- HTTP client for network requests
- Audio session configuration

### YouTube Music Integration ✅ COMPLETE
- **InnerTubeClient**: Full InnerTube protocol implementation
  - HTTP requests with proper headers
  - Session management with visitor data
  - SAPISIDHASH authentication
  - Client catalog (VISIONOS, IOS, ANDROID_MUSIC, ANDROID_VR, WEB_REMIX)
  - PoToken support structure
- **YTMusicRepository**: Complete API implementation
  - Home feed with pagination
  - Search with filters (All, Songs, Videos, Albums, Artists, Playlists)
  - Browse albums, artists, playlists
  - Library management (liked music, playlists)
  - Mood and genre categories
  - History and recents
  - Quick picks
  - Audio/video version resolution
- **InnertubeParser**: JSON response parsing
  - Home feed parsing (shelves, carousels)
  - Search result parsing (tracks, albums, artists)
  - Browse page parsing
  - Continuation token extraction
  - Artist and album page parsing
- **StreamResolver**: Multi-client stream resolution
  - Client fallback strategy (VISIONOS → IOS → ANDROID_MUSIC → ANDROID_VR)
  - Format selection (audio quality, bitrate)
  - Caching system for resolved URLs
  - Unplayable track detection
  - Loudness normalization support

### Audio Playback ✅ COMPLETE
- **PlaybackManager**: Full AVPlayer implementation
  - Queue management with tier system (USER_QUEUE, CONTEXT, AUTOPLAY)
  - Play/pause, next/previous, seek controls
  - Shuffle and repeat modes (off, all, one)
  - Playback rate and volume control
  - Queue drag and drop
  - Auto-skip on errors
  - Time observers for progress tracking
- **AudioSessionManager**: Lock screen and remote controls
  - MPNowPlayingInfoCenter integration
  - Remote command center (play, pause, skip, seek)
  - Now playing artwork display
  - Metadata updates

### UI Implementation ✅ COMPLETE
- Tab-based navigation (Home, Explore, Library, Search)
- Home screen with recents and shelves
- Explore screen with mood/genre categories
- Library screen with tabs (tracks, albums, artists, playlists)
- Search screen with filters and history
- Mini player dock with controls
- Now playing sheet with full controls
- Design system with theme and components
- Settings screen with segmented picker

### Library Management ✅ COMPLETE
- **LibraryManager**: Full library management
  - Save/remove tracks, albums, artists
  - Create/edit/delete playlists
  - Pin/unpin playlists
  - Add/remove songs from playlists
  - Move songs within playlists
  - YouTube Music library sync
  - Recently played tracking
  - Download tracking
  - Search within library
  - Statistics (total tracks, albums, artists, playlists)

### Lyrics Integration ✅ COMPLETE
- **LyricsProviders**: Multiple provider support
  - LRCLIB provider (synced and plain lyrics)
  - Genius provider (plain lyrics)
  - Musixmatch provider (optional API key)
  - Provider fallback system
- **LRC Parser**: LRC format parsing
  - Time tag parsing ([mm:ss.xx])
  - Line ordering
  - Support for enhanced LRC
- **LyricsManager**: Unified lyrics interface
  - Fetch lyrics with fallback
  - Synced lyrics support
  - Plain lyrics fallback

### Settings ✅ COMPLETE
- **SettingsManager**: Full settings persistence
  - Playback settings (quality, crossfade, speed, silence, normalization, gapless, sleep timer)
  - Appearance settings (theme, artwork-driven theming)
  - Library settings (view type, sort, swipe gestures)
  - Integration settings (Last.fm, ListenBrainz, Discord, Spotify)
  - Source settings (module sources, preferred source)
  - Party settings (server URL)
- **SettingsScreen**: Complete UI
  - Segmented picker for sections
  - Last.fm configuration view
  - ListenBrainz configuration view
  - Spotify configuration view
  - Account settings (sign in/out)
  - About section (version, license, GitHub)

### Integrations (Structure in Place) ⚠️ NEEDS WIRING
- **LastFMService**: Service structure exists, needs scrobbling logic
- **SpotifyService**: Service structure exists, needs OAuth and API calls
- **DiscordService**: Service structure exists, needs RPC implementation

### Advanced Features ✅ PARTIALLY IMPLEMENTED
- ✅ Animated artwork (subtle rotation and scale animations when playing)
- ✅ Sleep timer (auto-pause after specified time)
- ✅ Listening stats recorder (tracks play count, duration, top artists/songs)
- ✅ Playback tracker for YouTube Music recommendations
- ⚠️ Canvas artwork system (Apple Music, Spotify, Tidal) - NOT IMPLEMENTED
- ⚠️ Downloads and offline mode - NOT IMPLEMENTED
- ⚠️ Listen Together (party mode) - NOT IMPLEMENTED
- ⚠️ Advanced audio features (crossfade, equalizer) - SETTINGS UI EXISTS BUT NOT WIRED
- ⚠️ Background audio with full lock screen controls - PARTIALLY IMPLEMENTED
- ⚠️ Smart playlists - NOT IMPLEMENTED

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

### Immediate (Testing Required)
1. ✅ Build the project successfully
2. ✅ Test YouTube Music API integration on device (search working)
3. Test audio playback with real stream URLs
4. ✅ Test authentication flow (manual cookie entry working)
5. Test queue management
6. Test lyrics fetching and display
7. Test library operations
8. Test settings persistence

### Medium Priority
8. Wire up Last.fm scrobbling with PlaybackManager
9. Implement Spotify OAuth and library import
10. Implement Discord Rich Presence
11. Add canvas artwork system
12. Implement downloads and offline mode

### Lower Priority
13. Add advanced audio features (crossfade, equalizer)
14. Implement Listen Together (party mode)
15. Add smart playlists
16. Optimize performance and caching
17. Add comprehensive error handling

## Known Limitations

- YouTube Music InnerTube protocol may need updates as YouTube changes
- PoToken WebView implementation not yet added (for age-restricted content)
- Background audio requires proper Info.plist entitlements
- Some features may require third-party libraries (e.g., for equalizer)
- iOS sandbox restrictions limit some file system operations
- Real streaming integration requires handling of rate limits and authentication
- **Authentication WebView redirect**: The in-app WebView redirects to the official YouTube Music app on iOS. Workaround: Use manual cookie entry by extracting cookies from music.youtube.com in a desktop browser (via Developer Tools) and pasting them into the app's manual entry field.

## Testing

### Unit Tests
Test core business logic:
- Queue operations ✅ (implemented)
- LRC parsing ✅ (implemented)
- Settings persistence ✅ (implemented)

### Integration Tests Needed
- YouTube Music API calls
- Stream resolution
- Audio playback
- Authentication flow
- Lyrics fetching

### UI Tests Needed
- Navigation flows
- Playback controls
- Library operations
- Settings screen

## Dependencies

Current implementation uses only iOS system frameworks:
- SwiftUI
- AVFoundation
- MediaPlayer
- Foundation
- Combine

Future dependencies may include:
- Alamofire (networking) - optional, current HttpClient works
- Kingfisher (image loading) - optional, current image cache works
- SwiftDate (date handling) - optional, Foundation works
- lottie-ios (animations) - for canvas artwork

## Performance Considerations

- Image loading uses async/await with caching
- Lists use LazyVStack/LazyVGrid
- Search input should be debounced (add to implementation)
- Network requests are cancellable
- Audio playback remains responsive during navigation
- Stream URLs are cached with TTL

## Security

- All credentials stored in Keychain
- No hardcoded API keys
- OAuth flows for third-party integrations
- Secure HTTP only (HTTPS)
- Certificate pinning for critical endpoints (not yet implemented)

## Verification Commands

### Build
```bash
xcodebuild -project BitChord.xcodeproj -scheme BitChord -sdk iphonesimulator
```

### Run Tests
```bash
xcodebuild test -project BitChord.xcodeproj -scheme BitChord -sdk iphonesimulator
```

### Clean Build
```bash
xcodebuild clean -project BitChord.xcodeproj -scheme BitChord
```

## License

GPLv3 - matching the original BitChord project
