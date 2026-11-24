import Foundation

/// Playlist verisinin kaynağı. Üretimde `ProxyPlaylistSource`, testlerde ve
/// ekran görüntülerinde `SamplePlaylistSource` kullanılır.
public protocol PlaylistSource: Sendable {
    /// Tek bir sayfa döndürür. `pageToken` nil ise ilk sayfa.
    func fetchPage(playlistID: String, pageToken: String?) async throws -> PlaylistPage
}

public extension PlaylistSource {
    /// Tüm sayfaları sırayla çeker, tekrarlanan videoları atar.
    /// - Parameter maxPages: Sonsuz döngüye karşı üst sınır (50 öğe/sayfa → 10.000 öğe).
    func fetchPlaylist(
        id: String,
        maxPages: Int = 200,
        onProgress: (@Sendable (Int) async -> Void)? = nil
    ) async throws -> Playlist {
        var title: String?
        var videos: [PlaylistVideo] = []
        var seen = Set<String>()
        var unavailable = 0
        var token: String?
        var usedTokens = Set<String>()

        for _ in 0..<maxPages {
            try Task.checkCancellation()
            let page = try await fetchPage(playlistID: id, pageToken: token)
            if title == nil { title = page.title }
            unavailable += page.unavailableCount
            for video in page.videos where seen.insert(video.id).inserted {
                videos.append(video)
            }
            await onProgress?(videos.count)

            guard let next = page.nextPageToken, !next.isEmpty,
                  usedTokens.insert(next).inserted else { break }
            token = next
        }
        return Playlist(id: id, title: title, videos: videos, unavailableCount: unavailable)
    }
}
