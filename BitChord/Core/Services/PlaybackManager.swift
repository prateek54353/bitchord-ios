// Core/Services/Playback/PlaybackManager.swift
import Foundation
import AVFoundation
import Combine
import MediaPlayer

extension PlaybackManager {
    func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Clear any existing targets
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.nextTrackCommand.removeTarget(nil)
        commandCenter.previousTrackCommand.removeTarget(nil)
        commandCenter.changePlaybackPositionCommand.removeTarget(nil)
        
        // Play
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.resume()
            return .success
        }
        
        // Pause
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.pause()
            return .success
        }
        
        // Next Track
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.playNext()
            return .success
        }
        
        // Previous Track
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.playPrevious()
            return .success
        }
        
        // Scrubbing / Seeking
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self, 
                  let positionEvent = event as? MPChangePlaybackPositionCommandEvent,
                  self.duration > 0 else { return .commandFailed }
            
            let percentage = positionEvent.positionTime / self.duration
            self.seek(to: percentage)
            return .success
        }
    }
}
@MainActor
class PlaybackManager: ObservableObject {
    static let shared = PlaybackManager()
    
    // MARK: - Published State for SwiftUI
    @Published var currentTrack: Song?
    @Published var playbackState: PlaybackState = .stopped
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    
    // MARK: - AVPlayer Components
    private var player: AVPlayer = AVPlayer()
    private var timeObserver: Any?
    private var statusObserver: AnyCancellable?
    
    // MARK: - Queue System
    // Arrays hold tracks. The playNext() logic checks these in order.
    private var userQueue: [Song] = []
    private var contextQueue: [Song] = []
    private var autoplayQueue: [Song] = []
    private var history: [Song] = [] // For the "Previous" button
    
    // MARK: - Dependencies
    private let repository = YTMusicRepository() // Used to fetch stream URLs
    
    init() {
        setupAudioSession()
        setupTimeObserver()
    }
    
    // MARK: - Core Playback
    func play(song: Song) async {
        playbackState = .buffering
        currentTrack = song
        
        do {
            // 1. Fetch the actual stream URL from InnerTube
            let streamInfo = try await repository.fetchStreamData(videoId: song.id)
            guard let url = URL(string: streamInfo.url) else { throw URLError(.badURL) }
            
            // 2. Setup AVPlayerItem
            let playerItem = AVPlayerItem(url: url)
            
            // 3. Observe buffering/ready status
            observeItemStatus(item: playerItem)
            
            // 4. Play
            player.replaceCurrentItem(with: playerItem)
            player.play()
            playbackState = .playing
            
            // Note: In a full app, you'd also update MPNowPlayingInfoCenter here
            
        } catch {
            playbackState = .error(error)
        }
    }
    
    func pause() {
        player.pause()
        playbackState = .paused
    }
    
    func resume() {
        player.play()
        playbackState = .playing
    }
    
    func seek(to percentage: Double) {
        guard let item = player.currentItem else { return }
        let duration = item.duration.seconds
        guard duration.isFinite else { return }
        
        let targetTime = duration * percentage
        player.seek(to: CMTime(seconds: targetTime, preferredTimescale: 1000))
    }
    
    // MARK: - Queue Management
    func playNext() {
        if let current = currentTrack {
            history.append(current)
        }
        
        let nextSong: Song?
        
        // Tier 1: User Queue (Play Next)
        if !userQueue.isEmpty {
            nextSong = userQueue.removeFirst()
        } 
        // Tier 2: Context Queue (Album/Playlist)
        else if !contextQueue.isEmpty {
            nextSong = contextQueue.removeFirst()
        } 
        // Tier 3: Autoplay Queue (Infinite Radio)
        else if !autoplayQueue.isEmpty {
            nextSong = autoplayQueue.removeFirst()
            // Here you would trigger an async call to fetch MORE autoplay tracks
        } else {
            nextSong = nil
        }
        
        guard let track = nextSong else {
            playbackState = .stopped
            return
        }
        
        Task { await play(song: track) }
    }
    
    func playPrevious() {
        guard !history.isEmpty else {
            // If no history, restart current song
            seek(to: 0)
            return
        }
        
        if let current = currentTrack {
            // Push current back to the top of context queue so we don't lose it
            contextQueue.insert(current, at: 0)
        }
        
        let previousTrack = history.removeLast()
        Task { await play(song: previousTrack) }
    }
    
    // MARK: - API for adding to Queues
    func enqueue(_ song: Song, tier: QueueTier, playImmediately: Bool = false) {
        switch tier {
        case .user:
            userQueue.append(song)
        case .context:
            contextQueue.append(song)
        case .autoplay:
            autoplayQueue.append(song)
        }
        
        if playImmediately || playbackState == .stopped {
            playNext()
        }
    }
    
    func playContext(tracks: [Song], startIndex: Int = 0) {
        // Clear existing context
        contextQueue.removeAll()
        autoplayQueue.removeAll()
        
        guard startIndex < tracks.count else { return }
        
        let trackToPlay = tracks[startIndex]
        
        // Add remaining tracks to context queue
        if startIndex + 1 < tracks.count {
            contextQueue.append(contentsOf: tracks[(startIndex + 1)...])
        }
        
        Task { await play(song: trackToPlay) }
    }
    
    // MARK: - Private Setup
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.allowBluetooth, .allowBluetoothA2DP, .allowAirPlay]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    private func setupTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self, let item = self.player.currentItem else { return }
            
            self.currentTime = time.seconds
            
            let dur = item.duration.seconds
            if dur.isFinite {
                self.duration = dur
            }
            
            // Auto-advance to next track when finished
            if self.currentTime >= self.duration && self.duration > 0 {
                self.playNext()
            }
        }
    }
    
    private func observeItemStatus(item: AVPlayerItem) {
        statusObserver = item.publisher(for: \.status)
            .sink { [weak self] status in
                guard let self = self else { return }
                if status == .failed {
                    self.playbackState = .error(item.error ?? URLError(.unknown))
                    self.playNext() // Fallback to next track on error
                }
            }
    }
}