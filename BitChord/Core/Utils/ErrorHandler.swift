import Foundation
import SwiftUI
/// Centralized error handling
class ErrorHandler {
    static let shared = ErrorHandler()

    private init() {}

    // MARK: - Error Presentation

    func handleError(_ error: Error, context: String = "") {
        let errorMessage = errorMessage(for: error, context: context)
        print("Error: \(errorMessage)")

        // In production, this would show user-friendly alerts
        // For now, we'll just log
    }

    private func errorMessage(for error: Error, context: String) -> String {
        let baseMessage = context.isEmpty ? "" : "\(context): "

        if let httpError = error as? HttpError {
            switch httpError {
            case .invalidURL:
                return "\(baseMessage)Invalid URL"
            case .invalidResponse:
                return "\(baseMessage)Invalid server response"
            case .httpError(let code):
                return "\(baseMessage)HTTP error: \(code)"
            case .networkError(let underlying):
                return "\(baseMessage)Network error: \(underlying.localizedDescription)"
            }
        }

        if let innerTubeError = error as? InnerTubeError {
            switch innerTubeError {
            case .requestFailed:
                return "\(baseMessage)Failed to request YouTube Music"
            case .invalidResponse:
                return "\(baseMessage)Invalid response from YouTube Music"
            case .authenticationRequired:
                return "\(baseMessage)Authentication required"
            case .rateLimited:
                return "\(baseMessage)Rate limited by YouTube Music"
            }
        }

        if let streamError = error as? StreamError {
            switch streamError {
            case .noFormatsAvailable:
                return "\(baseMessage)No audio formats available"
            case .noSuitableFormat:
                return "\(baseMessage)No suitable audio format found"
            case .invalidResponse:
                return "\(baseMessage)Invalid stream response"
            case .unplayable(let reason):
                return "\(baseMessage)Track unplayable: \(reason)"
            case .ageRestricted:
                return "\(baseMessage)This track is age-restricted"
            }
        }

        if let lyricsError = error as? LyricsError {
            switch lyricsError {
            case .notFound:
                return "\(baseMessage)Lyrics not found"
            case .invalidResponse:
                return "\(baseMessage)Invalid lyrics response"
            case .networkError:
                return "\(baseMessage)Network error fetching lyrics"
            }
        }

        if let lastFMError = error as? LastFMError {
            switch lastFMError {
            case .notAuthenticated:
                return "\(baseMessage)Not authenticated with Last.fm"
            case .authenticationFailed:
                return "\(baseMessage)Last.fm authentication failed"
            case .invalidResponse:
                return "\(baseMessage)Invalid Last.fm response"
            }
        }

        if let spotifyError = error as? SpotifyError {
            switch spotifyError {
            case .notAuthenticated:
                return "\(baseMessage)Not authenticated with Spotify"
            case .authenticationFailed:
                return "\(baseMessage)Spotify authentication failed"
            case .invalidResponse:
                return "\(baseMessage)Invalid Spotify response"
            }
        }

        // Default error message
        return "\(baseMessage)\(error.localizedDescription)"
    }

    // MARK: - User-Friendly Messages

    func userMessage(for error: Error) -> String {
        if let httpError = error as? HttpError {
            switch httpError {
            case .networkError:
                return "Please check your internet connection and try again."
            case .httpError(let code):
                if code == 401 || code == 403 {
                    return "Authentication failed. Please sign in again."
                }
                if code >= 500 {
                    return "Server error. Please try again later."
                }
                return "Something went wrong. Please try again."
            default:
                return "Something went wrong. Please try again."
            }
        }

        if let innerTubeError = error as? InnerTubeError {
            switch innerTubeError {
            case .authenticationRequired:
                return "Please sign in to YouTube Music."
            case .rateLimited:
                return "You've been rate limited. Please wait a moment."
            default:
                return "Failed to connect to YouTube Music. Please try again."
            }
        }

        if let streamError = error as? StreamError {
            switch streamError {
            case .ageRestricted:
                return "This track is age-restricted. Please sign in to play it."
            default:
                return "This track is not available for playback."
            }
        }

        if let lyricsError = error as? LyricsError {
            switch lyricsError {
            case .notFound:
                return "Lyrics not found for this track."
            default:
                return "Failed to load lyrics."
            }
        }

        return "Something went wrong. Please try again."
    }
}

// MARK: - User-Facing Error View

struct ErrorView: View {
    let error: Error
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: BitChordTheme.spacingLg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(BitChordTheme.error)

            Text(ErrorHandler.shared.userMessage(for: error))
                .font(BitChordTheme.body)
                .foregroundColor(BitChordTheme.text)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: onRetry) {
                Text("Retry")
                    .font(BitChordTheme.callout)
                    .foregroundColor(.white)
                    .padding(.horizontal, BitChordTheme.spacingXl)
                    .padding(.vertical, BitChordTheme.spacingMd)
                    .background(BitChordTheme.primary)
                    .cornerRadius(BitChordTheme.radiusMd)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BitChordTheme.background)
    }
}
