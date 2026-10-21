// Core/Services/Playback/PlaybackState.swift
import Foundation

enum PlaybackState {
    case stopped
    case buffering
    case playing
    case paused
    case error(Error)
}

enum QueueTier {
    case user       // Explicitly queued by user (Play Next / Add to Queue)
    case context    // The current album/playlist being played
    case autoplay   // Infinite radio generated after context ends
}