import Foundation

/// Playlist'teki tek bir video.
public struct PlaylistVideo: Equatable, Hashable, Sendable, Identifiable, Decodable {
    public let id: String
    public let title: String

    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }

    /// Videonun izleme bağlantısı.
    public var watchURL: String { "https://www.youtube.com/watch?v=\(id)" }

    private enum CodingKeys: String, CodingKey {
        case id = "videoId"
        case title
    }
}

/// Veri kaynağından gelen tek sayfa.
public struct PlaylistPage: Equatable, Sendable {
    public var title: String?
    public var videos: [PlaylistVideo]
    /// Özel veya silinmiş olduğu için atlanan öğe sayısı.
    public var unavailableCount: Int
    public var nextPageToken: String?

    public init(title: String?, videos: [PlaylistVideo], unavailableCount: Int = 0, nextPageToken: String? = nil) {
        self.title = title
        self.videos = videos
        self.unavailableCount = unavailableCount
        self.nextPageToken = nextPageToken
    }
}

/// Tüm sayfaları birleştirilmiş playlist.
public struct Playlist: Equatable, Sendable {
    public let id: String
    public let title: String?
    public let videos: [PlaylistVideo]
    public let unavailableCount: Int
}
