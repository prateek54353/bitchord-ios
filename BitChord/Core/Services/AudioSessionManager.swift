import Foundation
import AVFoundation
import UIKit
import MediaPlayer
/// Audio session manager for configuring audio behavior
class AudioSessionManager {
    static let shared = AudioSessionManager()

    private init() {}

    func configure() {
        do {
            let session = AVAudioSession.sharedInstance()

            try session.setCategory(
                .playback,
                mode: .default,
                options: [
                    .allowAirPlay,
                    .allowBluetooth,
                    .allowBluetoothA2DP,
                    .mixWithOthers
                ]
            )

            try session.setActive(true)

            // Set up remote command center
            setupRemoteCommandCenter()

            // Set up now playing info
            setupNowPlayingInfo()
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] event in
            self?.handlePlayCommand()
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] event in
            self?.handlePauseCommand()
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] event in
            self?.handleNextTrackCommand()
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] event in
            self?.handlePreviousTrackCommand()
            return .success
        }

        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            if let event = event as? MPChangePlaybackPositionCommandEvent {
                self?.handleSeekCommand(event.positionTime)
            }
            return .success
        }
    }

    private func setupNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    func updateNowPlayingInfo(title: String, artist: String, album: String?, artwork: UIImage?, duration: TimeInterval, elapsedTime: TimeInterval) {
        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: artist,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsedTime,
            MPNowPlayingInfoPropertyPlaybackRate: 1.0
        ]

        if let album = album {
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = album
        }

        if let artwork = artwork {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: artwork.size) { _ in
                artwork
            }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    // MARK: - Command Handlers

    private func handlePlayCommand() {
        NotificationCenter.default.post(name: .remotePlayCommand, object: nil)
    }

    private func handlePauseCommand() {
        NotificationCenter.default.post(name: .remotePauseCommand, object: nil)
    }

    private func handleNextTrackCommand() {
        NotificationCenter.default.post(name: .remoteNextTrackCommand, object: nil)
    }

    private func handlePreviousTrackCommand() {
        NotificationCenter.default.post(name: .remotePreviousTrackCommand, object: nil)
    }

    private func handleSeekCommand(_ position: TimeInterval) {
        NotificationCenter.default.post(name: .remoteSeekCommand, object: nil, userInfo: ["position": position])
    }
}

extension Notification.Name {
    static let remotePlayCommand = Notification.Name("remotePlayCommand")
    static let remotePauseCommand = Notification.Name("remotePauseCommand")
    static let remoteNextTrackCommand = Notification.Name("remoteNextTrackCommand")
    static let remotePreviousTrackCommand = Notification.Name("remotePreviousTrackCommand")
    static let remoteSeekCommand = Notification.Name("remoteSeekCommand")
}
