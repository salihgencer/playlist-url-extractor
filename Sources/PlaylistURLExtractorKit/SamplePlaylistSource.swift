import Foundation

/// Ağsız, sabit veri döndüren kaynak. Birim testlerinde ve (yalnız DEBUG) ekran görüntüsü
/// üretiminde kullanılır. Videolar kurgusaldır; ID'ler gerçek videolara karşılık gelmez.
public struct SamplePlaylistSource: PlaylistSource {
    public static let playlistID = "PLsampleWorkshop2026"
    public static let title = "Swift Concurrency Workshop"

    public static let videos: [PlaylistVideo] = [
        ("SwCnc01aAaA", "01 · Welcome and setup"),
        ("SwCnc02bBbB", "02 · async and await basics"),
        ("SwCnc03cCcC", "03 · Structured concurrency with task groups"),
        ("SwCnc04dDdD", "04 · Cancellation done right"),
        ("SwCnc05eEeE", "05 · Actors and data isolation"),
        ("SwCnc06fFfF", "06 · The main actor and UI updates"),
        ("SwCnc07gGgG", "07 · Sendable in practice"),
        ("SwCnc08hHhH", "08 · AsyncSequence and streams"),
        ("SwCnc09iIiI", "09 · Bridging callbacks with continuations"),
        ("SwCnc10jJjJ", "10 · Testing async code"),
        ("SwCnc11kKkK", "11 · Performance and debugging"),
        ("SwCnc12lLlL", "12 · Wrap-up and Q&A"),
    ].map { PlaylistVideo(id: $0.0, title: $0.1) }

    private let pageSize: Int
    private let failure: PlaylistError?

    /// - Parameters:
    ///   - pageSize: Sayfalamayı denemek için sayfa başına öğe sayısı.
    ///   - failure: Verilirse her istek bu hatayla sonuçlanır.
    public init(pageSize: Int = 50, failure: PlaylistError? = nil) {
        self.pageSize = pageSize
        self.failure = failure
    }

    public func fetchPage(playlistID: String, pageToken: String?) async throws -> PlaylistPage {
        if let failure { throw failure }
        let start = pageToken.flatMap(Int.init) ?? 0
        let end = min(start + pageSize, Self.videos.count)
        return PlaylistPage(
            title: Self.title,
            videos: Array(Self.videos[start..<end]),
            unavailableCount: 0,
            nextPageToken: end < Self.videos.count ? String(end) : nil
        )
    }
}
