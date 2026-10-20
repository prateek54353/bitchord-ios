# BitChord for iOS

A native iOS music player built with SwiftUI, inspired by the BitChord Android application.

## Features

### Current Implementation
- ✅ Core app architecture with MVVM pattern
- ✅ Data models (Song, Playlist, BrowseItem, Lyrics, Settings)
- ✅ State management (AppState, PlaybackManager, LibraryManager, SettingsManager)
- ✅ Authentication system (AuthManager with Keychain storage)
- ✅ Local storage (LocalStorageService, KeychainService, ImageCache)
- ✅ HTTP client for network requests
- ✅ YouTube Music InnerTube protocol implementation
- ✅ Stream URL resolution
- ✅ Audio session management with remote controls
- ✅ Design system with theme and components
- ✅ Home screen with recents
- ✅ Explore screen with mood/genre categories
- ✅ Library screen (tracks, albums, artists, playlists)
- ✅ Search screen with filters
- ✅ Settings screen with all options
- ✅ Mini player dock
- ✅ Now playing sheet with full controls
- ✅ Queue management UI
- ✅ Lyrics providers (LRCLIB, Genius)
- ✅ Last.fm scrobbling service
- ✅ Spotify integration service
- ✅ Discord Rich Presence service
- ✅ SwiftData integration for persistence
- ✅ Unit tests (45 test cases)
- ✅ GitHub Actions for unsigned IPA builds

### Planned Features
- ⏳ Lyrics display UI (providers ready)
- ⏳ Canvas artwork (animated backgrounds)
- ⏳ Listen Together (party mode)
- ⏳ Local file playback
- ⏳ Downloads and offline mode
- ⏳ Advanced audio features (crossfade, equalizer)
- ⏳ Additional lyric providers

## Architecture

The app follows a modular architecture with clear separation of concerns:

- **Core/Models**: Data models (Song, Playlist, BrowseItem, etc.)
- **Core/Services**: Business logic (PlaybackManager, LibraryManager, etc.)
- **Core/Repositories**: Data layer (YTMusicRepository)
- **Core/Networking**: HTTP client
- **Core/Storage**: Persistence (LocalStorageService, KeychainService)
- **DesignSystem**: UI components and theming
- **Features**: Feature-specific screens (Home, Explore, Library, Search, etc.)

## Building

### GitHub Actions (Recommended for Unsigned IPA)
The repository includes GitHub Actions workflows to build unsigned IPAs automatically:

1. **Push to GitHub** - Workflows trigger on push to `main` or `develop` branches
2. **Download IPA** - Get the unsigned IPA from the Actions tab artifacts
3. **Install** - Use AltStore, Sideloadly, or Xcode to install on your device

See [GITHUB_ACTIONS_GUIDE.md](GITHUB_ACTIONS_GUIDE.md) for detailed instructions.

### Local Build with Xcode
#### Prerequisites
- Xcode 15.0 or later
- iOS 17.0 or later
- Swift 5.9 or later

#### Building
1. Open `BitChord.xcodeproj` in Xcode
2. Select a target device (iOS Simulator or physical device)
3. Build and run (⌘R)

### Project Structure
```
BitChord/
├── BitChord/
│   ├── Core/
│   │   ├── Models/
│   │   ├── Services/
│   │   ├── Repositories/
│   │   ├── Networking/
│   │   ├── Storage/
│   │   └── Utils/
│   ├── DesignSystem/
│   │   ├── Components/
│   │   ├── Theme/
│   │   └── Icons/
│   ├── Features/
│   │   ├── Home/
│   │   ├── Explore/
│   │   ├── Library/
│   │   ├── Search/
│   │   ├── Settings/
│   │   ├── Auth/
│   │   ├── Lyrics/
│   │   └── Integrations/
│   └── Resources/
└── BitChordTests/
```

## Contributing

This is a work in progress. The project is being developed to match the feature set of the Android BitChord application.

## License

This project is licensed under the GNU General Public License v3.0 (GPLv3), matching the original BitChord project.

## Disclaimer

BitChord is not affiliated with, endorsed by, or connected to YouTube or Google in any way. Use it at your own discretion.
