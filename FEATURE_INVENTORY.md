# BitChord iOS - Feature Inventory

Based on analysis of the BitChord Android reference repository (v1.8.1)

## Core Architecture
- **Language**: Swift with SwiftUI
- **Target**: iOS 17+ (latest stable SDK)
- **Architecture**: MVVM with clear separation of concerns
- **Concurrency**: Structured concurrency with async/await
- **Dependency Injection**: Protocol-based service abstractions
- **Storage**: SwiftData for persistence, Keychain for credentials

## Phase 1: Core Playback Features ✅ MUST IMPLEMENT

### Audio Playback Engine
- [ ] AVPlayer-based playback engine
- [ ] Play, pause, resume, stop controls
- [ ] Previous/next track navigation
- [ ] Seek within track (scrubber)
- [ ] Current playback time and duration display
- [ ] Repeat modes (off, all, one)
- [ ] Shuffle mode
- [ ] Queue management (add, remove, reorder)
- [ ] Queue tiers (user queue, context queue, autoplay)
- [ ] Playback state persistence
- [ ] Audio session configuration
- [ ] Interruption handling (calls, other audio)
- [ ] Background audio support with proper entitlements
- [ ] Lock screen metadata and controls (MPNowPlayingInfoCenter)
- [ ] Remote control events (headphones, Bluetooth)
- [ ] Network failure handling
- [ ] Invalid/unavailable track handling

### Queue System
- [ ] QueueCoordinator for queue state management
- [ ] Queue entry identity tracking
- [ ] Context queue (album/playlist context)
- [ ] User queue (explicitly queued tracks)
- [ ] Autoplay queue (radio recommendations)
- [ ] Queue persistence across app restarts
- [ ] Queue edit operations (move, remove, add to front)
- [ ] Radio queue generation
- [ ] Queue shuffle with preserve context option

### Audio Quality & Effects
- [ ] Crossfade (0-12 seconds adjustable)
- [ ] Playback speed control (0.5x - 2.0x)
- [ ] Skip silence
- [ ] Loudness normalization (ReplayGain-style)
- [ ] System equalizer integration
- [ ] Audio quality selection per network type (WiFi/mobile)
- [ ] Gapless playback
- [ ] Sleep timer (presets + "stop after this track")

## Phase 2: Music Source Integration ✅ MUST IMPLEMENT

### YouTube Music Integration
- [ ] YouTube Music API client (InnerTube protocol)
- [ ] Stream URL resolution
- [ ] Authentication (Google account sign-in)
- [ ] Cookie management and persistence
- [ ] Account channel switching
- [ ] Personalized content (library, likes, history)
- [ ] Search integration
- [ ] Browse endpoints (home, explore, moods)
- [ ] PoToken generation for stream access
- [ ] Fallback to NewPipeExtractor if needed

### Local Library
- [ ] Local file picker (iOS file picker)
- [ ] Security-scoped resource access
- [ ] Metadata reading from local files
- [ ] Local file playback
- [ ] Thumbnail generation for local files
- [ ] Library scanning and indexing

### Pluggable Sources (Module System)
- [ ] Source registry and configuration
- [ ] Source health checking
- [ ] Source selection UI
- [ ] Hi-Res lossless audio support (FLAC/ALAC)
- [ ] Source quality metadata display
- [ ] Source fallback chain

## Phase 3: User Interface ✅ MUST IMPLEMENT

### Navigation Structure
- [ ] Tab-based navigation (Home, Explore, Library, Search)
- [ ] Navigation stack management
- [ ] Deep linking support
- [ ] Back navigation handling

### Home Screen
- [ ] Home feed with shelves/carousels
- [ ] Recents shelf (recently played)
- [ ] New releases shelf
- [ ] Recommended shelves
- [ ] Pull-to-refresh
- [ ] Infinite scroll pagination
- [ ] Skeleton loading states
- [ ] Empty states
- [ ] Error states with retry

### Search Screen
- [ ] Search field with debouncing
- [ ] Search filters (All, Songs, Videos, Albums, Artists, Playlists)
- [ ] Top track promotion
- [ ] Search results grouping
- [ ] Search history
- [ ] Recent searches display
- [ ] Clear history

### Explore Screen
- [ ] Mood/genre sections
- [ ] Category browsing
- [ ] Featured playlists
- [ ] New releases

### Library Screen
- [ ] Saved tracks
- [ ] Saved albums
- [ ] Saved artists
- [ ] User playlists
- [ ] Downloads
- [ ] Local device music
- [ ] Pinned playlists
- [ ] Sort options
- [ ] View type toggle (list/grid)
- [ ] Swipe actions (play next, add to queue, remove)

### Detail Screens
- [ ] Album detail screen
- [ ] Artist detail screen
- [ ] Playlist detail screen
- [ ] Track list with metadata
- [ ] Play all/shuffle all
- [ ] Add to library
- [ ] Share functionality

### Now Playing Screen
- [ ] Full-screen player
- [ ] Album artwork display
- [ ] Animated artwork canvas (Apple Music-style)
- [ ] Track metadata (title, artist, album)
- [ ] Playback controls (play/pause, skip, previous)
- [ ] Scrubber with time display
- [ ] Repeat/shuffle mode indicators
- [ ] Queue button
- [ ] Lyrics button
- [ ] More options menu
- [ ] Stats for nerds (codec, bit depth, sample rate)
- [ ] Background color extraction from artwork
- [ ] Smooth transitions

### Mini-Player
- [ ] Persistent mini-player dock
- [ ] Expand/collapse gesture
- [ ] Play/pause control
- [ ] Progress indicator
- [ ] Track info display
- [ ] Swipe to dismiss

### Queue Screen
- [ ] Queue list display
- [ ] Queue tier indicators
- [ ] Remove from queue
- [ ] Move in queue
- [ ] Play next
- [ ] Clear queue

### Lyrics Screen
- [ ] Lyrics display with word-synced highlighting
- [ ] Multiple lyric providers (lrc.red, BiniLyrics, BetterLyrics, LRCLIB, Genius, etc.)
- [ ] LRC timestamp parsing
- [ ] Sync with playback
- [ ] Auto-scroll to current line
- [ ] Tap to seek (when timestamps available)
- [ ] Plain text fallback for unsynced lyrics
- [ ] Provider selection and priority
- [ ] Manual refresh
- [ ] Lyrics offset adjustment
- [ ] Apple-like lyrics animation
- [ ] Background blur with artwork colors

## Phase 4: Authentication & Accounts ✅ MUST IMPLEMENT

### Google/YouTube Music Authentication
- [ ] OAuth 2.0 flow for Google
- [ ] WebView-based authentication
- [ ] Cookie storage (Keychain)
- [ ] Session persistence
- [ ] Account profile display
- [ ] Account channel switching
- [ ] Sign out

### Spotify Integration
- [ ] Spotify OAuth flow
- [ ] Token management
- [ ] Playlist import
- [ ] Liked Songs access
- [ ] Spotify library browsing
- [ ] Account disconnection

### Last.fm Integration
- [ ] Last.fm authentication
- [ ] Scrobbling configuration
- [ ] API key/secret management (secure storage)
- [ ] Scrobble on track play
- [ ] Now playing updates
- [ ] Account management

### ListenBrainz Integration
- [ ] ListenBrainz authentication
- [ ] Scrobbling support
- [ ] Account management

### Discord Rich Presence
- [ ] Discord OAuth
- [ ] Rich presence display
- [ ] Track/artist/album info
- [ ] Playback progress
- [ ] In-app login

## Phase 5: Lyrics System ✅ MUST IMPLEMENT

### Core Lyrics
- [ ] LRC parser
- [ ] Timestamp extraction
- [ ] Word-level timing support
- [ ] Active line calculation
- [ ] Lyric matching (artist, title, album, duration)
- [ ] Lyrics caching
- [ ] Cache invalidation

### Lyric Providers
- [ ] lrc.red provider
- [ ] BiniLyrics provider
- [ ] BetterLyrics provider
- [ ] LRCLIB provider
- [ ] Genius provider
- [ ] KuGou provider
- [ ] Megalobiz provider
- [ ] Musixmatch provider
- [ ] Provider fallback chain
- [ ] Provider health checking

### Lyrics UI
- [ ] Synced lyrics display
- [ ] Word highlighting
- [ ] Smooth scrolling
- [ ] Tap to seek
- [ ] Manual offset
- [ ] Provider selector
- [ ] Empty state (no lyrics)
- [ ] Error state (fetch failed)

## Phase 6: Library & Playlists ✅ MUST IMPLEMENT

### User Library
- [ ] Save tracks
- [ ] Save albums
- [ ] Save artists
- [ ] Remove from library
- [ ] Library sync with YouTube Music
- [ ] Like status tracking
- [ ] Offline library view

### Playlists
- [ ] Create playlist
- [ ] Edit playlist name/description
- [ ] Add tracks to playlist
- [ ] Remove tracks from playlist
- [ ] Reorder tracks
- [ ] Delete playlist
- [ ] Pin playlists
- [ ] Playlist sort options

### Downloads
- [ ] Download tracks for offline
- [ ] Download management
- [ ] Download progress display
- [ ] Cancel downloads
- [ ] Remove downloads
- [ ] Storage management
- [ ] Embedded metadata in downloads

### History & Stats
- [ ] Recently played tracking
- [ ] Listening statistics
- [ ] Artist facts
- [ ] Replay listening history
- [ ] Search history

## Phase 7: Canvas/Animated Artwork ✅ SHOULD IMPLEMENT

### Canvas Sources
- [ ] Apple Music Canvas
- [ ] Spotify Canvas
- [ ] Tidal Canvas
- [ ] Community Canvas
- [ ] Canvas caching
- [ ] Canvas playback

### Canvas UI
- [ ] Animated artwork in Now Playing
- [ ] Mesh gradient background
- [ ] Artist signatures
- [ ] Smooth looping

## Phase 8: Social Features ✅ SHOULD IMPLEMENT

### Listen Together (Party Mode)
- [ ] Party creation
- [ ] Party join via link
- [ ] Synchronized playback
- [ ] Party queue
- [ ] Member list
- [ ] Server configuration
- [ ] Party sync protocol

### Sharing
- [ ] Share track link
- [ ] Share album/playlist link
- [ ] Deep link handling
- [ ] Intent handling

## Phase 9: Settings & Configuration ✅ MUST IMPLEMENT

### Playback Settings
- [ ] Audio quality (WiFi/mobile)
- [ ] Crossfade duration
- [ ] Playback speed
- [ ] Skip silence toggle
- [ ] Loudness normalization
- [ ] Gapless playback
- [ ] Automix settings
- [ ] Sleep timer

### Appearance Settings
- [ ] Theme mode (light/dark/auto)
- [ ] Artwork-driven theming
- [ ] Language selection
- [ ] Font size (Dynamic Type support)

### Library Settings
- [ ] Home recents view type
- [ ] Library sort order
- [ ] Swipe to play next toggle
- [ ] Pinned playlists management

### Account Settings
- [ ] Google account management
- [ ] Spotify account
- [ ] Last.fm account
- [ ] ListenBrainz account
- [ ] Discord account
- [ ] Sign out options

### Source Settings
- [ ] Module source editor
- [ ] Source health check
- [ ] Source priority
- [ ] Custom source configuration

### Party Settings
- [ ] Party server URL
- [ ] Party member limits

### About
- [ ] App version
- [ ] License information
- [ ] Links (GitHub, support)

## Phase 10: Persistence & Caching ✅ MUST IMPLEMENT

### Data Storage
- [ ] SwiftData models for:
  - [ ] Saved tracks/albums/artists
  - [ ] User playlists
  - [ ] Settings
  - [ ] Search history
  - [ ] Recently played
  - [ ] Downloads metadata
  - [ ] Listening stats
- [ ] Keychain for:
  - [ ] Auth tokens
  - [ ] Cookies
  - [ ] API keys
  - [ ] Encrypted preferences

### Caching
- [ ] Artwork image cache (disk + memory)
- [ ] Audio cache (streamed audio)
- [ ] Canvas cache
- [ ] Lyrics cache
- [ ] API response cache
- [ ] Cache size limits
- [ ] Cache eviction policy
- [ ] Cache invalidation on app update

## Phase 11: Error Handling ✅ MUST IMPLEMENT

### Network Errors
- [ ] Offline detection
- [ ] Retry logic with exponential backoff
- [ ] Rate limit handling
- [ ] Timeout handling
- [ ] Clear error messages

### API Errors
- [ ] Invalid responses
- [ ] Authentication errors
- [ ] 404/not found
- [ ] Server errors

### Playback Errors
- [ ] Unavailable tracks
- [ ] Invalid media URLs
- [ ] Unsupported formats
- [ ] Corrupted files

### User Feedback
- [ ] Error toasts
- [ ] Error dialogs
- [ ] Retry buttons
- [ ] Offline indicators

## Phase 12: Performance ✅ MUST IMPLEMENT

### Optimization
- [ ] Image loading optimization (async, caching)
- [ ] Lazy loading for lists
- [ ] Debounced search input
- [ ] Request cancellation
- [ ] Memory management
- [ ] Background thread usage
- [ ] Efficient view recomposition

### Metrics
- [ ] App launch time
- [ ] Screen transition smoothness
- [ ] Playback startup time
- [ ] Memory usage monitoring

## Phase 13: Testing ✅ SHOULD IMPLEMENT

### Unit Tests
- [ ] Queue operations
- [ ] LRC parsing
- [ ] Active lyric calculation
- [ ] Models validation
- [ ] Settings persistence
- [ ] Search algorithms

### UI Tests
- [ ] Critical user flows
- [ ] Navigation
- [ ] Playback controls

## Phase 14: Build & Delivery ✅ MUST IMPLEMENT

### Project Configuration
- [ ] Xcode project setup
- [ ] Info.plist configuration
- [ ] Entitlements (background audio, etc.)
- [ ] Bundle identifiers
- [ ] Versioning
- [ ] Signing configuration

### Dependencies
- [ ] Swift Package Manager setup
- [ ] Dependency versioning (7+ day rule)
- [ ] No hardcoded credentials

### GitHub Actions
- [ ] Checkout
- [ ] Xcode version selection
- [ ] Dependency resolution
- [ ] Build for iOS simulator
- [ ] Run tests
- [ ] Build logs
- [ ] Optional: export build with signing

## Implementation Priority

### Critical (MVP)
1. Basic playback (play/pause, seek, queue)
2. YouTube Music integration
3. Core UI (Home, Search, Library, Now Playing)
4. Authentication (Google)
5. Basic lyrics

### High Priority
6. Local library
7. Playlists
8. Settings
9. Last.fm integration
10. Background playback

### Medium Priority
11. Advanced audio features (crossfade, equalizer)
12. Spotify integration
13. Canvas artwork
14. Listen Together
15. Discord Rich Presence

### Lower Priority
16. Additional lyric providers
17. Advanced stats
18. Wear companion (if applicable)
19. TV companion (if applicable)

## Known Limitations

- iOS sandbox restrictions may limit some features (e.g., file system access)
- Background audio requires proper Info.plist entitlements
- Some YouTube Music features may not be accessible via API
- Third-party integrations depend on API availability
- Hi-Res audio support depends on source availability
