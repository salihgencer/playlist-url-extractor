import AppKit
import SwiftUI

/// Menü çubuğu öğesi ve popover'ı yönetir.
@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private let viewModel: ExtractorViewModel

    private static let hasLaunchedKey = "hasLaunchedBefore"

    public init(viewModel: ExtractorViewModel) {
        self.viewModel = viewModel
    }

    public convenience override init() {
        self.init(viewModel: ExtractorViewModel())
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: Brand.menuBarSymbol,
                accessibilityDescription: "Playlist URL Extractor"
            )
            button.action = #selector(togglePopover)
            button.target = self
        }

        popover = NSPopover()
        popover.contentSize = PopoverView.size
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: PopoverView(viewModel: viewModel))

        // İlk açılışta popover'ı göster: menü çubuğu uygulaması olduğu anlaşılsın.
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: Self.hasLaunchedKey) {
            defaults.set(true, forKey: Self.hasLaunchedKey)
            DispatchQueue.main.async { [weak self] in self?.showPopover() }
        }
    }

    /// Uygulama çalışırken Finder/Launchpad'den yeniden açılırsa popover'ı göster.
    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showPopover()
        return false
    }

    @objc private func togglePopover() {
        popover.isShown ? popover.performClose(nil) : showPopover()
    }

    private func showPopover() {
        guard let button = statusItem.button, !popover.isShown else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
    }
}
