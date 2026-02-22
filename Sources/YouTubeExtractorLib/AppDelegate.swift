import Cocoa
import SwiftUI

/// Menu bar uygulamasının ana delegesi.
/// NSStatusItem ile system tray ikonu, NSPopover ile açılır panel yönetir.
public class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu bar ikonu oluştur
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "play.rectangle.fill",
                accessibilityDescription: "YouTube Extractor"
            )
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Popover — dışına tıklayınca otomatik kapanır
        popover = NSPopover()
        popover.contentSize = NSSize(width: 380, height: 480)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: PopoverView(viewModel: ExtractorViewModel())
        )
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
