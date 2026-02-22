import XCTest
@testable import YouTubeExtractorLib

final class FetcherTests: XCTestCase {

    // MARK: - ValidateURL testleri

    func testValidateURL_GeçerliPlaylist() {
        XCTAssertNoThrow(try YouTubeFetcher.validateURL("https://www.youtube.com/playlist?list=PLxxxxxxxx"))
    }

    func testValidateURL_GeçerliPlaylistEkParametreli() {
        XCTAssertNoThrow(try YouTubeFetcher.validateURL("https://www.youtube.com/watch?v=abc123&list=PLxxxxxxxx"))
    }

    func testValidateURL_BoşURL() {
        XCTAssertThrowsError(try YouTubeFetcher.validateURL(""))
    }

    func testValidateURL_HTTPŞeması() {
        XCTAssertThrowsError(try YouTubeFetcher.validateURL("http://www.youtube.com/playlist?list=PLxxxxxxxx")) { error in
            XCTAssertTrue(error is FetcherError)
        }
    }

    func testValidateURL_FileŞeması() {
        XCTAssertThrowsError(try YouTubeFetcher.validateURL("file:///etc/passwd"))
    }

    func testValidateURL_YouTubeDışıDomain() {
        XCTAssertThrowsError(try YouTubeFetcher.validateURL("https://evil.com/playlist?list=PLxxxxxxxx"))
    }

    func testValidateURL_Localhost() {
        XCTAssertThrowsError(try YouTubeFetcher.validateURL("https://localhost:8080/playlist?list=PLxxxxxxxx"))
    }

    func testValidateURL_PlaylistParametresiYok() {
        XCTAssertThrowsError(try YouTubeFetcher.validateURL("https://www.youtube.com/watch?v=abc123"))
    }

    func testValidateURL_MobilYouTube() {
        XCTAssertNoThrow(try YouTubeFetcher.validateURL("https://m.youtube.com/playlist?list=PLxxxxxxxx"))
    }

    func testValidateURL_MusicYouTube() {
        XCTAssertNoThrow(try YouTubeFetcher.validateURL("https://music.youtube.com/playlist?list=PLxxxxxxxx"))
    }
}
