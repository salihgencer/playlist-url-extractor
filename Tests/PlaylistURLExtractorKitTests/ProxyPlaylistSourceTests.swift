import XCTest
@testable import PlaylistURLExtractorKit

final class ProxyPlaylistSourceTests: XCTestCase {
    private let base = URL(string: "https://proxy.test/playlist-url-extractor/")!

    override func setUp() {
        StubURLProtocol.requests = []
        StubURLProtocol.handler = nil
    }

    private func source() -> ProxyPlaylistSource {
        ProxyPlaylistSource(baseURL: base, session: StubURLProtocol.session())
    }

    private func json(_ object: Any) -> Data {
        try! JSONSerialization.data(withJSONObject: object)
    }

    func testRequestURL() {
        let url = source().requestURL(playlistID: "PLabc_-1", pageToken: "CAUQAA")
        XCTAssertEqual(url.absoluteString, "https://proxy.test/playlist-url-extractor/playlist?id=PLabc_-1&pageToken=CAUQAA")
        XCTAssertEqual(source().requestURL(playlistID: "PLabc", pageToken: nil).absoluteString,
                       "https://proxy.test/playlist-url-extractor/playlist?id=PLabc")
    }

    func testDefaultBaseURL() {
        XCTAssertEqual(ProxyPlaylistSource.defaultBaseURL.absoluteString,
                       "https://api.salihgencer.com/playlist-url-extractor/")
    }

    func testFetchesAllPages() async throws {
        StubURLProtocol.handler = { request in
            let token = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "pageToken" })?.value
            switch token {
            case nil:
                return .init(body: self.json([
                    "playlist": ["id": "PLx", "title": "Talks"],
                    "items": [["videoId": "aaaaaaaaaaa", "title": "One"], ["videoId": "bbbbbbbbbbb", "title": "Two"]],
                    "unavailable": 1, "nextPageToken": "P2", "totalResults": 4,
                ]))
            default:
                return .init(body: self.json([
                    "playlist": ["id": "PLx", "title": NSNull()],
                    "items": [["videoId": "bbbbbbbbbbb", "title": "Two"], ["videoId": "ccccccccccc", "title": "Three"]],
                    "unavailable": 0, "nextPageToken": NSNull(), "totalResults": 4,
                ]))
            }
        }
        let playlist = try await source().fetchPlaylist(id: "PLx")
        XCTAssertEqual(playlist.title, "Talks")
        XCTAssertEqual(playlist.videos.map(\.id), ["aaaaaaaaaaa", "bbbbbbbbbbb", "ccccccccccc"])
        XCTAssertEqual(playlist.unavailableCount, 1)
        XCTAssertEqual(StubURLProtocol.requests.count, 2)
        XCTAssertEqual(StubURLProtocol.requests.first?.value(forHTTPHeaderField: "Accept"), "application/json")
    }

    func testErrorCodesMapToUserErrors() async {
        let cases: [(Int, String, PlaylistError)] = [
            (404, "PLAYLIST_NOT_FOUND", .notFound),
            (403, "PLAYLIST_PRIVATE", .privatePlaylist),
            (400, "PLAYLIST_UNSUPPORTED", .unsupportedPlaylist),
            (400, "INVALID_ID", .invalidInput),
            (503, "QUOTA_EXCEEDED", .quotaExceeded),
            (429, "RATE_LIMITED", .rateLimited),
            (502, "UPSTREAM_ERROR", .serviceUnavailable),
        ]
        for (status, code, expected) in cases {
            StubURLProtocol.handler = { _ in .init(status: status, body: self.json(["error": code, "message": "x"])) }
            do {
                _ = try await source().fetchPage(playlistID: "PLx", pageToken: nil)
                XCTFail("hata bekleniyordu: \(code)")
            } catch {
                XCTAssertEqual(error as? PlaylistError, expected, code)
            }
        }
    }

    func testNonJSONErrorFallsBackToStatus() async {
        StubURLProtocol.handler = { _ in .init(status: 500, body: Data("<html>".utf8)) }
        do {
            _ = try await source().fetchPage(playlistID: "PLx", pageToken: nil)
            XCTFail()
        } catch {
            XCTAssertEqual(error as? PlaylistError, .serviceUnavailable)
        }
    }

    func testMalformedSuccessBody() async {
        StubURLProtocol.handler = { _ in .init(status: 200, body: Data("{\"nope\":1}".utf8)) }
        do {
            _ = try await source().fetchPage(playlistID: "PLx", pageToken: nil)
            XCTFail()
        } catch {
            XCTAssertEqual(error as? PlaylistError, .badResponse)
        }
    }

    func testOffline() async {
        StubURLProtocol.handler = { _ in .init(error: URLError(.notConnectedToInternet)) }
        do {
            _ = try await source().fetchPage(playlistID: "PLx", pageToken: nil)
            XCTFail()
        } catch {
            XCTAssertEqual(error as? PlaylistError, .offline)
        }
    }

    func testTimeoutIsServiceUnavailable() {
        XCTAssertEqual(ProxyPlaylistSource.map(urlError: URLError(.timedOut)), .serviceUnavailable)
    }
}
