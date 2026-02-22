import SwiftUI

/// Ana iş mantığı ViewModel'i. UI state'i yönetir, fetcher ve parser'ı koordine eder.
/// @MainActor — tüm @Published güncellemeleri ana thread'de yapılır (Go'daki fyne.Do karşılığı).
@MainActor
public class ExtractorViewModel: ObservableObject {
    @Published public var urlText = ""
    @Published public var videoURLs: [String] = []
    @Published public var statusMessage = ""
    @Published public var isError = false
    @Published public var isLoading = false

    private let fetcher = YouTubeFetcher()
    private let parser = PlaylistParser()
    private var currentTask: Task<Void, Never>?

    public init() {}

    /// Playlist URL'inden video URL'lerini çıkarır
    public func extract() {
        let url = urlText.trimmingCharacters(in: .whitespaces)
        guard !url.isEmpty else {
            setStatus("Lütfen bir URL girin", isError: true)
            return
        }

        do {
            try YouTubeFetcher.validateURL(url)
        } catch {
            setStatus("Geçersiz URL: sadece YouTube playlist desteklenir", isError: true)
            return
        }

        isLoading = true
        videoURLs = []
        setStatus("Video URL'leri çıkarılıyor...", isError: false)

        // Önceki görevi iptal et (Go'daki context.WithCancel karşılığı)
        currentTask?.cancel()
        currentTask = Task {
            do {
                let html = try await fetcher.fetchHTML(url: url)

                guard !Task.isCancelled else { return }

                let ids = try parser.extractVideoIDs(from: html)

                videoURLs = ids.map { "https://www.youtube.com/watch?v=\($0)" }
                setStatus("\(videoURLs.count) video URL'si bulundu", isError: false)
            } catch {
                if !Task.isCancelled {
                    setStatus("Hata oluştu, URL'yi kontrol edin", isError: true)
                }
            }
            isLoading = false
        }
    }

    /// Devam eden çıkarma işlemini iptal eder
    public func cancelExtraction() {
        currentTask?.cancel()
        isLoading = false
    }

    /// Panodan YouTube URL'si yapıştırır (doğrulama ile)
    public func pasteFromClipboard() {
        guard let content = NSPasteboard.general.string(forType: .string)?
                .trimmingCharacters(in: .whitespaces),
              !content.isEmpty else { return }

        do {
            try YouTubeFetcher.validateURL(content)
            urlText = content
        } catch {
            setStatus("Panodaki içerik geçerli bir YouTube URL'si değil", isError: true)
        }
    }

    /// Tüm URL'leri panoya kopyalar
    public func copyAll() {
        guard !videoURLs.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(videoURLs.joined(separator: "\n"), forType: .string)
        setStatus("\(videoURLs.count) URL panoya kopyalandı", isError: false)
    }

    private func setStatus(_ message: String, isError: Bool) {
        statusMessage = message
        self.isError = isError
    }
}
