import Foundation

/// Kullanıcının yapıştırdığı metinden (playlist bağlantısı veya çıplak ID) playlist ID'si çıkarır.
/// Ağ isteği yapmaz; yalnızca ID'yi ayıklar ve biçimini doğrular.
public enum PlaylistInput {
    /// Playlist bağlantısı kabul edilen alan adları.
    static let allowedHosts: Set<String> = [
        "youtube.com", "www.youtube.com", "m.youtube.com", "music.youtube.com", "youtu.be"
    ]

    /// Playlist ID'lerinde izin verilen karakterler ve uzunluk.
    private static let idPattern = try! NSRegularExpression(pattern: "^[A-Za-z0-9_-]{2,64}$")

    /// Metinden playlist ID'si döndürür; geçersizse `PlaylistError` fırlatır.
    public static func playlistID(from text: String) throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw PlaylistError.emptyInput }

        let id: String
        if trimmed.contains("/") || trimmed.contains("?") || trimmed.contains(".") {
            id = try idFromLink(trimmed)
        } else {
            id = trimmed
        }

        guard isValidID(id) else { throw PlaylistError.invalidInput }
        try rejectUnsupported(id)
        return id
    }

    static func isValidID(_ id: String) -> Bool {
        idPattern.firstMatch(in: id, range: NSRange(id.startIndex..., in: id)) != nil
    }

    private static func idFromLink(_ text: String) throws -> String {
        // Şemasız bağlantıları da kabul et ("youtube.com/playlist?list=...").
        let withScheme = text.contains("://") ? text : "https://" + text
        guard let components = URLComponents(string: withScheme),
              let scheme = components.scheme?.lowercased(),
              scheme == "https" || scheme == "http",
              let host = components.host?.lowercased(),
              allowedHosts.contains(host) else {
            throw PlaylistError.invalidInput
        }
        guard let value = components.queryItems?.first(where: { $0.name == "list" })?.value,
              !value.isEmpty else {
            throw PlaylistError.notAPlaylistLink
        }
        return value
    }

    /// Otomatik karışımlar (RD…) ve kişisel listeler (WL, LL) API ile listelenemez.
    private static func rejectUnsupported(_ id: String) throws {
        if id.hasPrefix("RD") || ["WL", "LL", "HL"].contains(id) {
            throw PlaylistError.unsupportedPlaylist
        }
    }
}
