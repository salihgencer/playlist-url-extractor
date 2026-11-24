import AppKit
import SwiftUI

/// Popover'ın durumunu yönetir; veri kaynağını (`PlaylistSource`) koordine eder.
@MainActor
public final class ExtractorViewModel: ObservableObject {
    public enum Status: Equatable {
        case idle
        case loading(found: Int)
        case success
        case copied(Int)
        case saved
        case saveFailed
        case failure(PlaylistError)
    }

    @Published public var inputText = ""
    @Published public private(set) var playlist: Playlist?
    @Published public private(set) var status: Status = .idle

    private let source: PlaylistSource
    private let pasteboard: NSPasteboard
    private var currentTask: Task<Void, Never>?

    public init(source: PlaylistSource = ProxyPlaylistSource(), pasteboard: NSPasteboard = .general) {
        self.source = source
        self.pasteboard = pasteboard
    }

    public var videos: [PlaylistVideo] { playlist?.videos ?? [] }
    public var isLoading: Bool { if case .loading = status { return true } else { return false } }
    public var isError: Bool {
        switch status {
        case .failure, .saveFailed: return true
        default: return false
        }
    }

    /// Bağlantı listesi (her satırda bir izleme bağlantısı).
    public var exportText: String { videos.map(\.watchURL).joined(separator: "\n") }

    /// Durum satırında gösterilen yerelleştirilmiş metin.
    public var statusMessage: String {
        switch status {
        case .idle:
            return ""
        case .loading(let found):
            return found == 0
                ? L10n.string("Fetching playlist…")
                : L10n.string("Fetching playlist… \(found) videos so far")
        case .success:
            let count = videos.count
            let skipped = playlist?.unavailableCount ?? 0
            if count == 0 { return L10n.string("This playlist has no available videos.") }
            if skipped > 0 { return L10n.string("\(count) videos found, \(skipped) private or deleted skipped") }
            return L10n.string("\(count) videos found")
        case .copied(let count):
            return L10n.string("\(count) links copied to the clipboard")
        case .saved:
            return L10n.string("File saved")
        case .saveFailed:
            return L10n.string("The file couldn't be saved.")
        case .failure(let error):
            return error.errorDescription ?? ""
        }
    }

    /// Girilen bağlantıdaki playlist'in tüm videolarını çeker.
    public func extract() {
        let id: String
        do {
            id = try PlaylistInput.playlistID(from: inputText)
        } catch {
            status = .failure(error as? PlaylistError ?? .invalidInput)
            return
        }

        currentTask?.cancel()
        playlist = nil
        status = .loading(found: 0)

        let source = self.source
        let report: @Sendable (Int) async -> Void = { [weak self] found in
            await self?.reportProgress(found)
        }
        currentTask = Task { [weak self] in
            do {
                let result = try await source.fetchPlaylist(id: id, onProgress: report)
                guard !Task.isCancelled, let self else { return }
                self.playlist = result
                self.status = .success
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled, let self else { return }
                self.status = .failure(error as? PlaylistError ?? .serviceUnavailable)
            }
        }
    }

    private func reportProgress(_ found: Int) {
        if isLoading { status = .loading(found: found) }
    }

    /// Devam eden işlemi iptal eder.
    public func cancel() {
        currentTask?.cancel()
        currentTask = nil
        if isLoading { status = .idle }
    }

    /// Panodaki metni giriş alanına alır.
    public func pasteFromClipboard() {
        guard let content = pasteboard.string(forType: .string)?
            .trimmingCharacters(in: .whitespacesAndNewlines), !content.isEmpty else { return }
        inputText = content
        if (try? PlaylistInput.playlistID(from: content)) != nil {
            if case .failure = status { status = .idle }
        } else {
            status = .failure(.invalidInput)
        }
    }

    /// Tüm bağlantıları panoya kopyalar.
    public func copyAll() {
        guard !videos.isEmpty else { return }
        pasteboard.clearContents()
        pasteboard.setString(exportText, forType: .string)
        status = .copied(videos.count)
    }

    /// Bağlantıları verilen dosyaya yazar.
    public func save(to url: URL) {
        do {
            try (exportText + "\n").write(to: url, atomically: true, encoding: .utf8)
            status = .saved
        } catch {
            status = .saveFailed
        }
    }

    /// Kayıt panelinde önerilen dosya adı.
    public var suggestedFileName: String {
        let base = (playlist?.title ?? "playlist")
            .components(separatedBy: CharacterSet(charactersIn: "/\\:?%*|\"<>"))
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespaces)
        return (base.isEmpty ? "playlist" : base) + " links.txt"
    }

    #if DEBUG
    /// Yalnız DEBUG: ekran görüntüsü için durumu doğrudan ayarlar.
    func setForScreenshot(playlist: Playlist?, status: Status) {
        self.playlist = playlist
        self.status = status
    }
    #endif
}
