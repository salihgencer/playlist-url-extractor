import Foundation

/// Kullanıcıya gösterilen hata türleri. Metinler String Catalog'dan (en/tr) gelir.
public enum PlaylistError: Error, Equatable, LocalizedError {
    case emptyInput
    case invalidInput
    case notAPlaylistLink
    case unsupportedPlaylist
    case notFound
    case privatePlaylist
    case quotaExceeded
    case rateLimited
    case offline
    case serviceUnavailable
    case badResponse

    public var errorDescription: String? {
        switch self {
        case .emptyInput:
            return L10n.string("Paste a playlist link or ID first.")
        case .invalidInput:
            return L10n.string("That doesn't look like a playlist link or ID.")
        case .notAPlaylistLink:
            return L10n.string("This link has no playlist in it. Use a link that contains “list=”.")
        case .unsupportedPlaylist:
            return L10n.string("Mixes, Watch Later and Liked lists can't be listed. Try a regular public playlist.")
        case .notFound:
            return L10n.string("Playlist not found. It may have been deleted, or the link is incomplete.")
        case .privatePlaylist:
            return L10n.string("This playlist is private. Only public and unlisted playlists can be listed.")
        case .quotaExceeded:
            return L10n.string("The daily lookup limit has been reached. Please try again tomorrow.")
        case .rateLimited:
            return L10n.string("Too many requests. Please wait a minute and try again.")
        case .offline:
            return L10n.string("No internet connection. Check your network and try again.")
        case .serviceUnavailable:
            return L10n.string("The service is temporarily unavailable. Please try again later.")
        case .badResponse:
            return L10n.string("Received an unexpected response. Please try again later.")
        }
    }
}
