#if DEBUG
import AppKit
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

/// Yalnız DEBUG derlemelerinde: App Store ekran görüntülerini (2880x1800, alfa kanalsız PNG)
/// gerçek `PopoverView` ile ve ağsız `SamplePlaylistSource` verisiyle üretir.
///
///     "Playlist URL Extractor" -RenderScreenshots <klasör> -AppleLanguages "(tr)"
@MainActor
enum ScreenshotRenderer {
    private static let canvas = CGSize(width: 2880, height: 1800)
    private static let privateLink = "https://www.youtube.com/playlist?list=PLprivateTeamNotes"
    private static let sampleLink = "https://www.youtube.com/playlist?list=\(SamplePlaylistSource.playlistID)"

    static func runIfRequested() -> Bool {
        let args = ProcessInfo.processInfo.arguments
        guard let flag = args.firstIndex(of: "-RenderScreenshots"), flag + 1 < args.count else { return false }
        let outDir = URL(fileURLWithPath: args[flag + 1], isDirectory: true)

        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        app.activate(ignoringOtherApps: true)
        let language = L10n.bundle.preferredLocalizations.first ?? "en"

        Task { @MainActor in
            do {
                try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
                let playlist = try await SamplePlaylistSource().fetchPlaylist(id: SamplePlaylistSource.playlistID)
                let scenes: [(String, ExtractorViewModel.Status, Playlist?, String, String)] = [
                    ("1-results", .success, playlist,
                     L10n.string("Every link in a playlist, in one click"),
                     L10n.string("Paste a public playlist link and get a clean list of video links right from your menu bar.")),
                    ("2-copy", .copied(playlist.videos.count), playlist,
                     L10n.string("Copy or save the whole list"),
                     L10n.string("Copy all links to the clipboard or save them as a plain text file.")),
                    ("3-errors", .failure(.privatePlaylist), nil,
                     L10n.string("Clear messages when something's wrong"),
                     L10n.string("Private, deleted or unsupported playlists are explained in plain words.")),
                ]
                for (name, status, list, title, subtitle) in scenes {
                    let vm = ExtractorViewModel(source: SamplePlaylistSource())
                    vm.inputText = list == nil ? privateLink : sampleLink
                    vm.setForScreenshot(playlist: list, status: status)
                    let popover = try await renderPopover(vm)
                    let image = try compose(popover: popover, title: title, subtitle: subtitle)
                    let url = outDir.appendingPathComponent("\(language)-\(name).png")
                    try writePNG(image, to: url)
                    print("yazıldı: \(url.path)")
                }
                exit(0)
            } catch {
                FileHandle.standardError.write(Data("ekran görüntüsü hatası: \(error)\n".utf8))
                exit(1)
            }
        }
        app.run()
        return true
    }

    // MARK: - Popover çizimi

    private static let popoverScale: CGFloat = 3 // piksel/nokta

    private static func renderPopover(_ vm: ExtractorViewModel) async throws -> CGImage {
        let size = PopoverView.size
        let root = PopoverView(viewModel: vm)
            .background(Color(nsColor: .windowBackgroundColor))
            .environment(\.colorScheme, .light)
        let hosting = NSHostingView(rootView: root)
        hosting.frame = NSRect(origin: .zero, size: size)
        let window = KeyWindow(contentRect: hosting.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.appearance = NSAppearance(named: .aqua)
        window.contentView = hosting
        window.setFrameOrigin(NSPoint(x: -10_000, y: -10_000))
        window.makeKeyAndOrderFront(nil)
        hosting.layoutSubtreeIfNeeded()
        // List (NSTableView) satırlarının dolması için run loop'a zaman tanı.
        try await Task.sleep(nanoseconds: 600_000_000)
        hosting.layoutSubtreeIfNeeded()

        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width * popoverScale), pixelsHigh: Int(size.height * popoverScale),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        ) else { throw RenderError.bitmap }
        rep.size = size
        hosting.cacheDisplay(in: hosting.bounds, to: rep)
        window.orderOut(nil)
        guard let image = rep.cgImage else { throw RenderError.bitmap }
        return image
    }

    // MARK: - Kompozisyon

    private static func compose(popover: CGImage, title: String, subtitle: String) throws -> CGImage {
        let width = Int(canvas.width), height = Int(canvas.height)
        guard let ctx = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { throw RenderError.bitmap }

        let previous = NSGraphicsContext.current
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
        defer { NSGraphicsContext.current = previous }

        // Arka plan: ikonla aynı lacivert → camgöbeği geçişi.
        let gradient = NSGradient(colors: [
            NSColor(red: 0.09, green: 0.16, blue: 0.42, alpha: 1),
            NSColor(red: 0.12, green: 0.36, blue: 0.74, alpha: 1),
            NSColor(red: 0.10, green: 0.62, blue: 0.70, alpha: 1),
        ])!
        gradient.draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: -35)

        // Popover: 1.5x nokta ölçeğinde, gölgeli yuvarlatılmış kart.
        let cardSize = CGSize(width: PopoverView.size.width * 3, height: PopoverView.size.height * 3)
        let card = CGRect(x: CGFloat(width) - cardSize.width - 220, y: (CGFloat(height) - cardSize.height) / 2,
                          width: cardSize.width, height: cardSize.height)
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -24), blur: 90, color: NSColor.black.withAlphaComponent(0.45).cgColor)
        let path = CGPath(roundedRect: card, cornerWidth: 36, cornerHeight: 36, transform: nil)
        ctx.addPath(path)
        ctx.setFillColor(NSColor.white.cgColor)
        ctx.fillPath()
        ctx.restoreGState()
        ctx.saveGState()
        ctx.addPath(path)
        ctx.clip()
        ctx.interpolationQuality = .high
        ctx.draw(popover, in: card)
        ctx.restoreGState()

        // Metinler (sol sütun).
        let textWidth = card.minX - 200 - 160
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 120, weight: .bold),
            .foregroundColor: NSColor.white,
        ]
        let subtitleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 60, weight: .regular),
            .foregroundColor: NSColor.white.withAlphaComponent(0.85),
        ]
        let nameAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 52, weight: .semibold),
            .foregroundColor: NSColor.white.withAlphaComponent(0.75),
        ]
        let titleString = NSAttributedString(string: title, attributes: titleAttrs)
        let subtitleString = NSAttributedString(string: subtitle, attributes: subtitleAttrs)
        let bound = CGSize(width: textWidth, height: .greatestFiniteMagnitude)
        let titleBox = titleString.boundingRect(with: bound, options: [.usesLineFragmentOrigin])
        let subtitleBox = subtitleString.boundingRect(with: bound, options: [.usesLineFragmentOrigin])
        let gap: CGFloat = 56
        let nameHeight: CGFloat = 70
        let blockHeight = nameHeight + gap + titleBox.height + gap + subtitleBox.height
        var y = (CGFloat(height) + blockHeight) / 2

        y -= nameHeight
        NSAttributedString(string: "Playlist URL Extractor", attributes: nameAttrs)
            .draw(at: CGPoint(x: 200, y: y))
        y -= gap + titleBox.height
        titleString.draw(with: CGRect(x: 200, y: y, width: textWidth, height: titleBox.height), options: [.usesLineFragmentOrigin])
        y -= gap + subtitleBox.height
        subtitleString.draw(with: CGRect(x: 200, y: y, width: textWidth, height: subtitleBox.height), options: [.usesLineFragmentOrigin])

        guard let image = ctx.makeImage() else { throw RenderError.bitmap }
        return image
    }

    private static func writePNG(_ image: CGImage, to url: URL) throws {
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
        else { throw RenderError.write }
        CGImageDestinationAddImage(dest, image, nil)
        guard CGImageDestinationFinalize(dest) else { throw RenderError.write }
    }

    enum RenderError: Error { case bitmap, write }

    /// Çerçevesiz pencere varsayılan olarak anahtar olamaz; kontroller etkin görünsün diye izin ver.
    private final class KeyWindow: NSWindow {
        override var canBecomeKey: Bool { true }
        override var canBecomeMain: Bool { true }
    }
}
#endif
