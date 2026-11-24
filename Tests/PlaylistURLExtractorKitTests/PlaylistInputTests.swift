import XCTest
@testable import PlaylistURLExtractorKit

final class PlaylistInputTests: XCTestCase {
    private let id = "PLOU2XLYxmsIIAOskSyap13n9W-xOt_GP5"

    func testPlaylistLink() throws {
        XCTAssertEqual(try PlaylistInput.playlistID(from: "https://www.youtube.com/playlist?list=\(id)"), id)
    }

    func testWatchLinkWithList() throws {
        XCTAssertEqual(try PlaylistInput.playlistID(from: "https://www.youtube.com/watch?v=abc123&list=\(id)&index=2"), id)
    }

    func testMobileMusicAndShortHosts() throws {
        XCTAssertEqual(try PlaylistInput.playlistID(from: "https://m.youtube.com/playlist?list=\(id)"), id)
        XCTAssertEqual(try PlaylistInput.playlistID(from: "https://music.youtube.com/playlist?list=\(id)"), id)
        XCTAssertEqual(try PlaylistInput.playlistID(from: "https://youtu.be/abc123?list=\(id)"), id)
    }

    func testLinkWithoutScheme() throws {
        XCTAssertEqual(try PlaylistInput.playlistID(from: "youtube.com/playlist?list=\(id)"), id)
    }

    func testBareIDWithWhitespace() throws {
        XCTAssertEqual(try PlaylistInput.playlistID(from: "  \(id)\n"), id)
    }

    func testEmpty() {
        XCTAssertThrowsError(try PlaylistInput.playlistID(from: "   ")) { XCTAssertEqual($0 as? PlaylistError, .emptyInput) }
    }

    func testForeignHostRejected() {
        XCTAssertThrowsError(try PlaylistInput.playlistID(from: "https://evil.example/playlist?list=\(id)")) {
            XCTAssertEqual($0 as? PlaylistError, .invalidInput)
        }
    }

    func testNonWebSchemeRejected() {
        XCTAssertThrowsError(try PlaylistInput.playlistID(from: "file:///etc/passwd")) {
            XCTAssertEqual($0 as? PlaylistError, .invalidInput)
        }
    }

    func testLinkWithoutList() {
        XCTAssertThrowsError(try PlaylistInput.playlistID(from: "https://www.youtube.com/watch?v=abc123")) {
            XCTAssertEqual($0 as? PlaylistError, .notAPlaylistLink)
        }
    }

    func testInvalidCharacters() {
        XCTAssertThrowsError(try PlaylistInput.playlistID(from: "PL<script>")) {
            XCTAssertEqual($0 as? PlaylistError, .invalidInput)
        }
        XCTAssertThrowsError(try PlaylistInput.playlistID(from: "https://www.youtube.com/playlist?list=PL%20bad")) {
            XCTAssertEqual($0 as? PlaylistError, .invalidInput)
        }
    }

    func testUnsupportedLists() {
        for value in ["RDdQw4w9WgXcQ", "WL", "LL"] {
            XCTAssertThrowsError(try PlaylistInput.playlistID(from: "https://www.youtube.com/playlist?list=\(value)")) {
                XCTAssertEqual($0 as? PlaylistError, .unsupportedPlaylist, value)
            }
        }
    }
}
