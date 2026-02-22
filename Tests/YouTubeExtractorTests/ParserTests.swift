import XCTest
@testable import YouTubeExtractorLib

final class ParserTests: XCTestCase {
    let parser = PlaylistParser()

    // MARK: - ExtractVideoIDs testleri

    func testExtractVideoIDs_GeçerliHTML() throws {
        let html = """
        <html><body><script>
        var ytInitialData = {"contents":{"playlistVideoListRenderer":{"contents":[{"playlistVideoRenderer":{"videoId":"abc123def45"}},{"playlistVideoRenderer":{"videoId":"xyz987uvw65"}},{"playlistVideoRenderer":{"videoId":"abc123def45"}}]}}};
        </script></body></html>
        """

        let ids = try parser.extractVideoIDs(from: html)
        // 3 entry, 2 unique (deduplicate çalışmalı)
        XCTAssertEqual(ids, ["abc123def45", "xyz987uvw65"])
    }

    func testExtractVideoIDs_BoşHTML() {
        XCTAssertThrowsError(try parser.extractVideoIDs(from: "")) { error in
            XCTAssertTrue(error is ParserError)
        }
    }

    func testExtractVideoIDs_MarkerYok() {
        let html = "<html><body><script>var x = 1;</script></body></html>"
        XCTAssertThrowsError(try parser.extractVideoIDs(from: html))
    }

    func testExtractVideoIDs_VideoIDYok() {
        let html = #"<script>var ytInitialData = {"contents":{"empty": true}};</script>"#
        XCTAssertThrowsError(try parser.extractVideoIDs(from: html))
    }

    func testExtractVideoIDs_TekVideo() throws {
        let html = #"<script>var ytInitialData = {"playlistVideoRenderer":{"videoId":"single12345"}};</script>"#
        let ids = try parser.extractVideoIDs(from: html)
        XCTAssertEqual(ids, ["single12345"])
    }

    func testExtractVideoIDs_WindowMarker() throws {
        let html = #"<script>window["ytInitialData"] = {"playlistVideoRenderer":{"videoId":"win_marker01"}};</script>"#
        let ids = try parser.extractVideoIDs(from: html)
        XCTAssertEqual(ids, ["win_marker01"])
    }

    func testExtractVideoIDs_EscapedQuotes() throws {
        let html = #"<script>var ytInitialData = {"title":"test \"quoted\"","videoId":"esc_quote_01"};</script>"#
        let ids = try parser.extractVideoIDs(from: html)
        XCTAssertEqual(ids, ["esc_quote_01"])
    }

    // MARK: - SliceBalancedJSON testleri

    func testSliceBalancedJSON_KapanmamışJSON() {
        XCTAssertThrowsError(try parser.sliceBalancedJSON(#"{"key": "value""#))
    }

    func testSliceBalancedJSON_FazladanKapanış() {
        XCTAssertThrowsError(try parser.sliceBalancedJSON(#"}{"key": "value"}"#)) { error in
            guard let parserError = error as? ParserError else {
                XCTFail("ParserError bekleniyor")
                return
            }
            XCTAssertEqual(parserError, .malformedJSON)
        }
    }

    func testSliceBalancedJSON_İçİçeJSON() throws {
        let input = #"{"a":{"b":{"c":"d"}},"e":"f"} garbage after"#
        let result = try parser.sliceBalancedJSON(input)
        XCTAssertEqual(result, #"{"a":{"b":{"c":"d"}},"e":"f"}"#)
    }

    func testSliceBalancedJSON_StringİçindeSüslüParantez() throws {
        let input = #"{"key":"value with { and } inside"}"#
        let result = try parser.sliceBalancedJSON(input)
        XCTAssertEqual(result, input)
    }
}
