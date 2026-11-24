import XCTest
@testable import PlaylistURLExtractorKit

final class LocalizationTests: XCTestCase {
    private func bundle(for language: String) throws -> Bundle {
        let path = try XCTUnwrap(L10n.bundle.path(forResource: language, ofType: "lproj"),
                                 "\(language).lproj bulunamadı")
        return try XCTUnwrap(Bundle(path: path))
    }

    /// Kaynak katalogdaki her anahtarın Türkçe karşılığı derlenmiş pakette olmalı.
    func testEveryKeyHasTurkish() throws {
        let catalogURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/PlaylistURLExtractorKit/Resources/Localizable.xcstrings")
        let catalog = try JSONSerialization.jsonObject(with: Data(contentsOf: catalogURL)) as! [String: Any]
        let strings = catalog["strings"] as! [String: Any]
        XCTAssertGreaterThan(strings.count, 30)
        let tr = try bundle(for: "tr")
        for key in strings.keys {
            let value = tr.localizedString(forKey: key, value: "__missing__", table: nil)
            XCTAssertNotEqual(value, "__missing__", key)
            if !key.contains("%") { XCTAssertNotEqual(value, key, "çevrilmemiş: \(key)") }
        }
    }

    func testTurkishPluralAndFormat() throws {
        let tr = try bundle(for: "tr")
        let format = tr.localizedString(forKey: "%lld videos found", value: nil, table: nil)
        XCTAssertEqual(String(format: format, locale: Locale(identifier: "tr"), 12), "12 video bulundu")
        XCTAssertEqual(tr.localizedString(forKey: "Extract Links", value: nil, table: nil), "Bağlantıları Çıkar")
    }

    func testEnglishPlural() throws {
        let en = try bundle(for: "en")
        let format = en.localizedString(forKey: "%lld videos found", value: nil, table: nil)
        XCTAssertEqual(String.localizedStringWithFormat(format, 1), "1 video found")
        XCTAssertEqual(String.localizedStringWithFormat(format, 12), "12 videos found")
        let two = en.localizedString(forKey: "%lld videos found, %lld private or deleted skipped", value: nil, table: nil)
        XCTAssertEqual(String.localizedStringWithFormat(two, 1, 2), "1 video found, 2 private or deleted skipped")
    }

    func testEveryErrorHasMessage() {
        let all: [PlaylistError] = [.emptyInput, .invalidInput, .notAPlaylistLink, .unsupportedPlaylist, .notFound,
                                    .privatePlaylist, .quotaExceeded, .rateLimited, .offline, .serviceUnavailable, .badResponse]
        for error in all { XCTAssertFalse((error.errorDescription ?? "").isEmpty, "\(error)") }
    }
}
