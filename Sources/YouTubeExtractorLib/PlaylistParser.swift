import Foundation

/// Parser hata türleri
public enum ParserError: Error, LocalizedError {
    case markerNotFound
    case noVideoIDs
    case malformedJSON

    public var errorDescription: String? {
        switch self {
        case .markerNotFound: return "ytInitialData bulunamadı"
        case .noVideoIDs: return "Video ID bulunamadı"
        case .malformedJSON: return "JSON yapısı bozuk"
        }
    }
}

/// YouTube playlist HTML'inden video ID'lerini çıkarır.
/// Go parser'ın birebir Swift portu: marker arama → sliceBalancedJSON → regex → dedup
public struct PlaylistParser {
    private static let markers = [
        "var ytInitialData",
        "window[\"ytInitialData\"]",
        "ytInitialData"
    ]

    private static let videoIDRegex = try! NSRegularExpression(
        pattern: #""videoId":"([a-zA-Z0-9_-]+)""#
    )

    public init() {}

    /// HTML içinden tekil video ID listesi döndürür
    public func extractVideoIDs(from html: String) throws -> [String] {
        let jsonPayload = try extractInitialDataJSON(from: html)

        let range = NSRange(jsonPayload.startIndex..., in: jsonPayload)
        let matches = Self.videoIDRegex.matches(in: jsonPayload, range: range)

        guard !matches.isEmpty else {
            throw ParserError.noVideoIDs
        }

        var seen = Set<String>()
        var ids: [String] = []

        for match in matches {
            guard match.numberOfRanges >= 2,
                  let idRange = Range(match.range(at: 1), in: jsonPayload) else { continue }
            let id = String(jsonPayload[idRange])
            if seen.insert(id).inserted {
                ids.append(id)
            }
        }

        return ids
    }

    // MARK: - Dahili yardımcılar

    private func extractInitialDataJSON(from html: String) throws -> String {
        for marker in Self.markers {
            guard let markerRange = html.range(of: marker) else { continue }

            let after = String(html[markerRange.lowerBound...])
            guard let braceIndex = after.firstIndex(of: "{") else { continue }

            let fromBrace = String(after[braceIndex...])
            if let json = try? sliceBalancedJSON(fromBrace) {
                return json
            }
        }

        throw ParserError.markerNotFound
    }

    /// Süslü parantez sayarak dengeli JSON bloğunu çıkarır.
    /// String içindeki { } karakterlerini ve escape dizilerini doğru handle eder.
    func sliceBalancedJSON(_ payload: String) throws -> String {
        var result = ""
        var inString = false
        var escape = false
        var braceCount = 0

        for ch in payload {
            result.append(ch)

            if escape {
                escape = false
                continue
            }

            switch ch {
            case "\\":
                escape = true
                continue
            case "\"":
                inString = !inString
                continue
            default:
                break
            }

            if inString { continue }

            switch ch {
            case "{":
                braceCount += 1
            case "}":
                braceCount -= 1
                if braceCount < 0 {
                    throw ParserError.malformedJSON
                }
                if braceCount == 0 {
                    return result
                }
            default:
                break
            }
        }

        throw ParserError.malformedJSON
    }
}
