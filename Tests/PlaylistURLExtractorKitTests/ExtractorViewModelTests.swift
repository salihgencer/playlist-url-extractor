import AppKit
import XCTest
@testable import PlaylistURLExtractorKit

@MainActor
final class ExtractorViewModelTests: XCTestCase {
    private var pasteboard: NSPasteboard!

    override func setUp() async throws {
        pasteboard = NSPasteboard(name: NSPasteboard.Name("test-\(UUID().uuidString)"))
    }

    override func tearDown() async throws {
        pasteboard.releaseGlobally()
    }

    private func waitUntilDone(_ vm: ExtractorViewModel) async {
        for _ in 0..<200 where vm.isLoading || vm.status == .idle {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    func testSuccessfulExtraction() async {
        let vm = ExtractorViewModel(source: SamplePlaylistSource(pageSize: 5), pasteboard: pasteboard)
        vm.inputText = "https://www.youtube.com/playlist?list=\(SamplePlaylistSource.playlistID)"
        vm.extract()
        await waitUntilDone(vm)
        XCTAssertEqual(vm.status, .success)
        XCTAssertEqual(vm.videos.count, SamplePlaylistSource.videos.count)
        XCTAssertEqual(vm.playlist?.title, SamplePlaylistSource.title)
        XCTAssertEqual(vm.exportText.split(separator: "\n").first, "https://www.youtube.com/watch?v=SwCnc01aAaA")
        XCTAssertFalse(vm.isError)
    }

    func testInvalidInputShowsErrorWithoutNetwork() {
        let vm = ExtractorViewModel(source: SamplePlaylistSource(failure: .serviceUnavailable), pasteboard: pasteboard)
        vm.inputText = "hello world"
        vm.extract()
        XCTAssertEqual(vm.status, .failure(.invalidInput))
        XCTAssertTrue(vm.isError)
        XCTAssertFalse(vm.statusMessage.isEmpty)
    }

    func testSourceErrorIsShown() async {
        let vm = ExtractorViewModel(source: SamplePlaylistSource(failure: .privatePlaylist), pasteboard: pasteboard)
        vm.inputText = "PLsomething"
        vm.extract()
        await waitUntilDone(vm)
        XCTAssertEqual(vm.status, .failure(.privatePlaylist))
        XCTAssertEqual(vm.statusMessage, PlaylistError.privatePlaylist.errorDescription)
        XCTAssertTrue(vm.videos.isEmpty)
    }

    func testCopyAll() async {
        let vm = ExtractorViewModel(source: SamplePlaylistSource(), pasteboard: pasteboard)
        vm.inputText = SamplePlaylistSource.playlistID
        vm.extract()
        await waitUntilDone(vm)
        vm.copyAll()
        XCTAssertEqual(vm.status, .copied(12))
        XCTAssertEqual(pasteboard.string(forType: .string)?.split(separator: "\n").count, 12)
    }

    func testPasteFromClipboard() {
        let vm = ExtractorViewModel(source: SamplePlaylistSource(), pasteboard: pasteboard)
        pasteboard.clearContents()
        pasteboard.setString(" https://www.youtube.com/playlist?list=PLabc ", forType: .string)
        vm.pasteFromClipboard()
        XCTAssertEqual(vm.inputText, "https://www.youtube.com/playlist?list=PLabc")
        XCTAssertEqual(vm.status, .idle)
    }

    func testSaveWritesOneLinkPerLine() async throws {
        let vm = ExtractorViewModel(source: SamplePlaylistSource(), pasteboard: pasteboard)
        vm.inputText = SamplePlaylistSource.playlistID
        vm.extract()
        await waitUntilDone(vm)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("pue-\(UUID().uuidString).txt")
        defer { try? FileManager.default.removeItem(at: url) }
        vm.save(to: url)
        XCTAssertEqual(vm.status, .saved)
        let lines = try String(contentsOf: url, encoding: .utf8).split(separator: "\n")
        XCTAssertEqual(lines.count, 12)
        XCTAssertEqual(vm.suggestedFileName, "Swift Concurrency Workshop links.txt")
    }
}
