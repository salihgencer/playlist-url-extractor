import Foundation

/// Playlist verisini geliştiricinin Cloudflare Worker'ı üzerinden resmi YouTube Data API v3'ten alır.
/// API anahtarı uygulamada YOKTUR; Worker (repo: proxy/) anahtarı secret olarak tutar.
public struct ProxyPlaylistSource: PlaylistSource {
    public static let defaultBaseURL = URL(string: "https://api.salihgencer.com/playlist-url-extractor/")!
    private static let maxBodySize = 2 * 1024 * 1024

    private let baseURL: URL
    private let session: URLSession

    /// Yalnız DEBUG: `defaults write com.salihgencer.PlaylistURLExtractor ProxyBaseURL <url>` ile
    /// (ör. `wrangler dev` veya workers.dev adresi) farklı bir uca bağlanır. Release'de her zaman varsayılan uç.
    public static var configuredBaseURL: URL {
        #if DEBUG
        if let value = UserDefaults.standard.string(forKey: "ProxyBaseURL"), let url = URL(string: value) {
            return url
        }
        #endif
        return defaultBaseURL
    }

    public init(baseURL: URL = ProxyPlaylistSource.configuredBaseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func requestURL(playlistID: String, pageToken: String?) -> URL {
        var components = URLComponents(url: baseURL.appendingPathComponent("playlist"), resolvingAgainstBaseURL: false)!
        var items = [URLQueryItem(name: "id", value: playlistID)]
        if let pageToken { items.append(URLQueryItem(name: "pageToken", value: pageToken)) }
        components.queryItems = items
        return components.url!
    }

    public func fetchPage(playlistID: String, pageToken: String?) async throws -> PlaylistPage {
        var request = URLRequest(url: requestURL(playlistID: playlistID, pageToken: pageToken), timeoutInterval: 20)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            if error.code == .cancelled { throw CancellationError() }
            throw Self.map(urlError: error)
        }

        guard let http = response as? HTTPURLResponse else { throw PlaylistError.badResponse }
        guard data.count <= Self.maxBodySize else { throw PlaylistError.badResponse }

        guard (200..<300).contains(http.statusCode) else {
            let code = (try? JSONDecoder().decode(ErrorBody.self, from: data))?.error
            throw Self.map(status: http.statusCode, code: code)
        }

        do {
            let body = try JSONDecoder().decode(PageBody.self, from: data)
            return PlaylistPage(
                title: body.playlist?.title,
                videos: body.items,
                unavailableCount: body.unavailable ?? 0,
                nextPageToken: body.nextPageToken
            )
        } catch {
            throw PlaylistError.badResponse
        }
    }

    // MARK: - Hata eşleme (proxy/src/index.ts ile aynı kodlar)

    static func map(status: Int, code: String?) -> PlaylistError {
        switch code {
        case "PLAYLIST_NOT_FOUND": return .notFound
        case "PLAYLIST_PRIVATE": return .privatePlaylist
        case "PLAYLIST_UNSUPPORTED": return .unsupportedPlaylist
        case "INVALID_ID": return .invalidInput
        case "QUOTA_EXCEEDED": return .quotaExceeded
        case "RATE_LIMITED": return .rateLimited
        default: break
        }
        switch status {
        case 404: return .notFound
        case 429: return .rateLimited
        case 400..<500: return .badResponse
        default: return .serviceUnavailable
        }
    }

    static func map(urlError: URLError) -> PlaylistError {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff:
            return .offline
        case .timedOut, .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed,
             .secureConnectionFailed, .serverCertificateUntrusted:
            return .serviceUnavailable
        default:
            return .serviceUnavailable
        }
    }

    private struct PageBody: Decodable {
        struct Meta: Decodable { let id: String?; let title: String? }
        let playlist: Meta?
        let items: [PlaylistVideo]
        let unavailable: Int?
        let nextPageToken: String?
    }

    private struct ErrorBody: Decodable { let error: String }
}
