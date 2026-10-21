import Foundation
import AVFoundation
import Combine
import MediaPlayer
import UIKit

/// Playback state
enum PlaybackState: Equatable {
    case idle
    case loading
    case playing
    case paused
    case error(String)
}

/// Repeat mode
enum RepeatMode: String, CaseIterable {
    case off = "Off"
    case all = "All"
    case one = "One"
}

/// Main playback manager using AVPlayer
/// Ported from Android's PlaybackService.kt
@MainActor
class PlaybackManager: NSObject, ObservableObject {
    @Published var playbackState: PlaybackState = .idle
    @Published var currentSong: Song?
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var isPlaying: Bool = false
    @Published var repeatMode: RepeatMode = .off
    @Published var isShuffled: Bool = false

    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var _queue: [Song] = []
    private var _queueIndex: Int = 0
    private var _originalQueue: [Song] = [] // For shuffle unshuffle
    private let streamResolver: StreamResolver
    private let audioSessionManager: AudioSessionManager

    // Playback state
    private var playbackRate: Float = 1.0
    private var volume: Float = 1.0

    init(
        streamResolver: StreamResolver = .shared,
        audioSessionManager: AudioSessionManager = .shared
    ) {
        self.streamResolver = streamResolver
        self.audioSessionManager = audioSessionManager
        setupAudioSession()
        setupRemoteCommands()
    }

    private func setupAudioSession() {
        audioSessionManager.configure()
    }

    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] event in
            self?.play()
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] event in
            self?.pause()
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] event in
            self?.next()
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] event in
            self?.previous()
            return .success
        }

        commandCenter.skipForwardCommand.addTarget { [weak self] event in
            let interval = event as? MPSkipIntervalCommandEvent
            self?.seek(relative: interval?.interval ?? 15)
            return .success
        }

        commandCenter.skipBackwardCommand.addTarget { [weak self] event in
            let interval = event as? MPSkipIntervalCommandEvent
            self?.seek(relative: -(interval?.interval ?? 15))
            return .success
        }

        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            let positionEvent = event as? MPChangePlaybackPositionCommandEvent
            self?.seek(to: positionEvent?.positionTime ?? 0)
            return .success
        }

        commandCenter.togglePlayPauseCommand.addTarget { [weak self] event in
            if self?.isPlaying == true {
                self?.pause()
            } else {
                self?.play()
            }
            return .success
        }
    }

    // MARK: - Queue Management

    func setQueue(_ songs: [Song], startIndex: Int = 0) {
        _queue = songs
        _originalQueue = songs
        _queueIndex = startIndex
    }

    func addToQueue(_ songs: [Song], at index: Int? = nil) {
        if let index = index {
            _queue.insert(contentsOf: songs, at: index)
            _originalQueue.insert(contentsOf: songs, at: index)
        } else {
            _queue.append(contentsOf: songs)
            _originalQueue.append(contentsOf: songs)
        }
    }

    func removeFromQueue(at index: Int) {
        guard index < _queue.count else { return }
        _queue.remove(at: index)
        _originalQueue.remove(at: index)
        if index < _queueIndex {
            _queueIndex -= 1
        }
    }

    func clearQueue() {
        _queue.removeAll()
        _originalQueue.removeAll()
        _queueIndex = 0
    }

    func moveItem(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex < _queue.count, destinationIndex < _queue.count else { return }
        let item = _queue.remove(at: sourceIndex)
        _queue.insert(item, at: destinationIndex)

        // Update original queue too
        let originalItem = _originalQueue.remove(at: sourceIndex)
        _originalQueue.insert(originalItem, at: destinationIndex)

        // Adjust current index if needed
        if sourceIndex == _queueIndex {
            _queueIndex = destinationIndex
        } else if sourceIndex < _queueIndex && destinationIndex >= _queueIndex {
            _queueIndex -= 1
        } else if sourceIndex > _queueIndex && destinationIndex <= _queueIndex {
            _queueIndex += 1
        }
    }

    // MARK: - Playback Controls

    func play(_ song: Song? = nil) {
        if let song = song {
            loadAndPlay(song)
        } else if currentSong != nil {
            resume()
        } else if !_queue.isEmpty {
            loadAndPlay(_queue[_queueIndex])
        }
    }

    func play(at index: Int) {
        guard index >= 0 && index < _queue.count else { return }
        _queueIndex = index
        loadAndPlay(_queue[index])
    }

    func pause() {
        player?.pause()
        isPlaying = false
        playbackState = .paused
        updateNowPlayingInfo()
    }

    func resume() {
        player?.play()
        isPlaying = true
        playbackState = .playing
        updateNowPlayingInfo()
    }

    func stop() {
        player?.pause()
        player?.seek(to: .zero)
        isPlaying = false
        playbackState = .idle
        updateNowPlayingInfo()
    }

    func next() {
        guard !_queue.isEmpty else { return }

        if isShuffled {
            _queueIndex = Int.random(in: 0..<_queue.count)
        } else {
            _queueIndex = (_queueIndex + 1) % _queue.count
        }

        loadAndPlay(_queue[_queueIndex])
    }

    func previous() {
        guard !_queue.isEmpty else { return }

        if currentTime > 3.0 {
            seek(to: 0)
        } else {
            _queueIndex = (_queueIndex - 1 + _queue.count) % _queue.count
            loadAndPlay(_queue[_queueIndex])
        }
    }

    func seek(to time: TimeInterval) {
        player?.seek(to: CMTime(seconds: time, preferredTimescale: 600))
        currentTime = time
        updateNowPlayingInfo()
    }

    func seek(relative seconds: TimeInterval) {
        let newTime = currentTime + seconds
        seek(to: max(0, min(newTime, duration)))
    }

    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        player?.rate = isPlaying ? rate : 0
    }

    func setVolume(_ vol: Float) {
        volume = vol
        player?.volume = vol
    }

    func toggleShuffle() {
        isShuffled.toggle()
        if isShuffled {
            _originalQueue = _queue
            _queue.shuffle()
            // Keep current position
            if let current = currentSong, let newIndex = _queue.firstIndex(where: { $0.videoId == current.videoId }) {
                _queueIndex = newIndex
            }
        } else {
            // Restore original order
            if let current = currentSong, let originalIndex = _originalQueue.firstIndex(where: { $0.videoId == current.videoId }) {
                _queue = _originalQueue
                _queueIndex = originalIndex
            } else {
                _queue = _originalQueue
            }
        }
    }

    func toggleRepeat() {
        switch repeatMode {
        case .off:
            repeatMode = .all
        case .all:
            repeatMode = .one
        case .one:
            repeatMode = .off
        }
    }

    // MARK: - Queue Access

    var queue: [Song] {
        get { _queue }
    }

    var queueIndex: Int {
        get { _queueIndex }
    }

    // MARK: - Private Methods

    private func loadAndPlay(_ song: Song) {
        currentSong = song
        playbackState = .loading

        Task {
            do {
                let streamInfo = try await streamResolver.resolveStreamUrl(videoId: song.videoId)
                guard let url = URL(string: streamInfo.url) else {
                    await MainActor.run {
                        playbackState = .error("Invalid stream URL")
                    }
                    return
                }

                await MainActor.run {
                    // Create new player item
                    let asset = AVURLAsset(url: url)
                    playerItem = AVPlayerItem(asset: asset)

                    // Apply headers if provided
                    if !streamInfo.headers.isEmpty {
                        // Note: AVURLAsset doesn't support custom headers directly
                        // This would require a custom resource loader
                    }

                    player = AVPlayer(playerItem: playerItem)

                    setupTimeObserver()
                    setupItemObservers()

                    player?.rate = playbackRate
                    player?.volume = volume

                    player?.play()
                    isPlaying = true
                    playbackState = .playing

                    updateNowPlayingInfo()
                }
            } catch {
                await MainActor.run {
                    playbackState = .error(error.localizedDescription)
                    // Auto-skip to next track on error
                    if _queue.count > 1 {
                        next()
                    }
                }
            }
        }
    }

    private func setupTimeObserver() {
        guard let player = player else { return }

        // Remove existing observer
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
        }

        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                self?.currentTime = time.seconds
                self?.duration = player.currentItem?.duration.seconds ?? 0
                self?.updateNowPlayingInfo()
            }
        }
    }

    private func setupItemObservers() {
        guard let playerItem = playerItem else { return }

        // Observe when playback ends
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handlePlaybackEnd()
            }
        }

        // Observe playback errors
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
                    self?.playbackState = .error(error.localizedDescription)
                }
            }
        }

        // Observe playback buffer status
        playerItem.addObserver(
            self,
            forKeyPath: "status",
            options: [.new, .initial],
            context: nil
        )
    }

    private func handlePlaybackEnd() {
        switch repeatMode {
        case .one:
            // Replay current track
            seek(to: 0)
            play()
        case .all:
            // Play next track
            next()
        case .off:
            // Stop if last track, otherwise play next
            if _queueIndex == _queue.count - 1 {
                stop()
            } else {
                next()
            }
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status", let playerItem = object as? AVPlayerItem {
            if playerItem.status == .readyToPlay {
                duration = playerItem.duration.seconds
                updateNowPlayingInfo()
            } else if playerItem.status == .failed {
                if let error = playerItem.error {
                    playbackState = .error(error.localizedDescription)
                }
            }
        }
    }

    private func updateNowPlayingInfo() {
        guard let song = currentSong else { return }

        var nowPlayingInfo = [String: Any]()

        nowPlayingInfo[MPMediaItemPropertyTitle] = song.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = song.artist
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? playbackRate : 0
        nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = playbackRate

        if let albumName = song.albumName {
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = albumName
        }

        // Note: MPMediaItemPropertyTrackNumber is deprecated/not available in all iOS versions
        // if let trackNumber = song.trackNumber {
        //     nowPlayingInfo[MPMediaItemPropertyTrackNumber] = trackNumber
        // }

        // Set artwork if available
        if let artworkUrl = song.artworkAt(px: Song.notificationArtPx),
           let url = URL(string: artworkUrl) {
            // Load artwork asynchronously
            Task {
                if let data = try? Data(contentsOf: url) {
                    #if canImport(UIKit)
                    if let image = UIImage(data: data) {
                        let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in
                            return image
                        }
                        nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                    }
                    #endif
                }
            }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    deinit {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        NotificationCenter.default.removeObserver(self)
    }
}
