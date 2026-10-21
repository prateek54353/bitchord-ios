import Foundation
import AVFoundation
import Combine

/// Playback state
enum PlaybackState: Equatable {
    case idle
    case loading
    case playing
    case paused
    case error(String)
}

/// Main playback manager using AVPlayer
@MainActor
class PlaybackManager: ObservableObject {
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
    private let streamResolver: StreamResolver

    init(streamResolver: StreamResolver = StreamResolver()) {
        self.streamResolver = streamResolver
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.allowAirPlay, .allowBluetooth]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    // MARK: - Queue Management

    func setQueue(_ songs: [Song], startIndex: Int = 0) {
        _queue = songs
        _queueIndex = startIndex
    }

    func addToQueue(_ songs: [Song], at index: Int? = nil) {
        if let index = index {
            _queue.insert(contentsOf: songs, at: index)
        } else {
            _queue.append(contentsOf: songs)
        }
    }

    func removeFromQueue(at index: Int) {
        guard index < _queue.count else { return }
        _queue.remove(at: index)
        if index < _queueIndex {
            _queueIndex -= 1
        }
    }

    func clearQueue() {
        _queue.removeAll()
        _queueIndex = 0
    }

    // MARK: - Playback Controls

    func play(_ song: Song? = nil) {
        if let song = song {
            loadAndPlay(song)
        } else if let currentItem = currentSong {
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

    // MARK: - Queue Access

    var queue: [Song] {
        get { _queue }
    }

    var queueIndex: Int {
        get { _queueIndex }
    }

    func pause() {
        player?.pause()
        isPlaying = false
        playbackState = .paused
    }

    func resume() {
        player?.play()
        isPlaying = true
        playbackState = .playing
    }

    func stop() {
        player?.pause()
        player?.seek(to: .zero)
        isPlaying = false
        playbackState = .idle
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
                    playerItem = AVPlayerItem(url: url)
                    player = AVPlayer(playerItem: playerItem)

                    setupTimeObserver()
                    setupItemObservers()

                    player?.play()
                    isPlaying = true
                    playbackState = .playing
                }
            } catch {
                await MainActor.run {
                    playbackState = .error(error.localizedDescription)
                }
            }
        }
    }

    private func setupTimeObserver() {
        guard let player = player else { return }

        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
            self?.duration = player.currentItem?.duration.seconds ?? 0
        }
    }

    private func setupItemObservers() {
        // TODO: Add observers for playback end, errors, etc.
    }

    deinit {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
    }
}
