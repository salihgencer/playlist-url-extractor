import Foundation

/// Fetcher hata türleri
public enum FetcherError: Error, LocalizedError {
    case invalidURL
    case notHTTPS
    case notYouTube
    case noPlaylistParam
    case httpError(Int)
    case responseTooLarge

    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "Geçersiz URL"
        case .notHTTPS: return "Yalnızca HTTPS desteklenir"
        case .notYouTube: return "Yalnızca YouTube URL'leri desteklenir"
        case .noPlaylistParam: return "URL bir playlist parametresi içermelidir"
        case .httpError(let code): return "HTTP hatası: \(code)"
        case .responseTooLarge: return "Yanıt çok büyük (10MB üstü)"
        }
    }
}

/// YouTube playlist sayfasından HTML çeken servis.
/// URL doğrulama, boyut sınırı ve YouTube domain kontrolü içerir.
public struct YouTubeFetcher {
    private static let maxBodySize = 10 * 1024 * 1024 // 10 MB
    private static let userAgent = "Mozilla/5.0 (compatible; YouTubePlaylistExtractor/1.0)"

    private static let youtubeHosts: Set<String> = [
        "youtube.com", "www.youtube.com", "m.youtube.com", "youtu.be"
    ]

    public init() {}

    /// URL'in geçerli bir YouTube playlist URL'si olduğunu doğrular
    public static func validateURL(_ urlString: String) throws {
        let trimmed = urlString.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            throw FetcherError.invalidURL
        }

        guard let url = URL(string: trimmed),
              let host = url.host?.lowercased(),
              let scheme = url.scheme?.lowercased() else {
            throw FetcherError.invalidURL
        }

        guard scheme == "https" else {
            throw FetcherError.notHTTPS
        }

        let isYouTube = youtubeHosts.contains(host) || host.hasSuffix(".youtube.com")
        guard isYouTube else {
            throw FetcherError.notYouTube
        }

        guard let components = URLComponents(string: trimmed),
              let listParam = components.queryItems?.first(where: { $0.name == "list" }),
              let value = listParam.value, !value.isEmpty else {
            throw FetcherError.noPlaylistParam
        }
    }

    /// YouTube playlist sayfasının HTML'ini async olarak çeker
    public func fetchHTML(url urlString: String) async throws -> String {
        try Self.validateURL(urlString)

        guard let url = URL(string: urlString) else {
            throw FetcherError.invalidURL
        }

        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FetcherError.invalidURL
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw FetcherError.httpError(httpResponse.statusCode)
        }

        guard data.count <= Self.maxBodySize else {
            throw FetcherError.responseTooLarge
        }

        guard let html = String(data: data, encoding: .utf8) else {
            throw FetcherError.invalidURL
        }

        return html
    }
}
