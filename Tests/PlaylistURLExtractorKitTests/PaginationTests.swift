import XCTest
@testable import PlaylistURLExtractorKit

final class PaginationTests: XCTestCase {
    func testSampleSourceIsConsistentAcrossPageSizes() async throws {
        for size in [1, 5, 50] {
            let playlist = try await SamplePlaylistSource(pageSize: size).fetchPlaylist(id: SamplePlaylistSource.playlistID)
            XCTAssertEqual(playlist.videos, SamplePlaylistSource.videos, "pageSize \(size)")
            XCTAssertEqual(playlist.videos.count, 12)
            XCTAssertEqual(Set(playlist.videos.map(\.id)).count, 12)
        }
    }

    /// 5000 öğelik (YouTube üst sınırı) liste 100 sayfa sürer; maxPages bunu kesmemeli.
    func testLargePlaylistNotTruncated() async throws {
        struct Big: PlaylistSource {
            func fetchPage(playlistID: String, pageToken: String?) async throws -> PlaylistPage {
                let page = Int(pageToken ?? "0")!
                let videos = (0..<50).map { PlaylistVideo(id: "v\(page)_\($0)", title: "Video") }
                return PlaylistPage(title: "Big", videos: videos, nextPageToken: page < 99 ? String(page + 1) : nil)
            }
        }
        let playlist = try await Big().fetchPlaylist(id: "PLbig")
        XCTAssertEqual(playlist.videos.count, 5000)
    }

    func testRepeatedTokenStopsLoop() async throws {
        struct Looping: PlaylistSource {
            func fetchPage(playlistID: String, pageToken: String?) async throws -> PlaylistPage {
                PlaylistPage(title: nil, videos: [PlaylistVideo(id: "same", title: "x")], nextPageToken: "again")
            }
        }
        let playlist = try await Looping().fetchPlaylist(id: "PL")
        XCTAssertEqual(playlist.videos.count, 1)
    }

    func testProgressReported() async throws {
        let counts = Counts()
        _ = try await SamplePlaylistSource(pageSize: 5).fetchPlaylist(id: "x") { await counts.add($0) }
        let values = await counts.values
        XCTAssertEqual(values, [5, 10, 12])
    }

    private actor Counts {
        var values: [Int] = []
        func add(_ v: Int) { values.append(v) }
    }
}
