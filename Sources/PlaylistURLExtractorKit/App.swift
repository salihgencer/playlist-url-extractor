import AppKit

/// Uygulamayı başlatır. Dock'ta görünmez, yalnızca menü çubuğunda yaşar.
@MainActor
public func startApp() {
    #if DEBUG
    if ScreenshotRenderer.runIfRequested() { return }
    #endif

    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.accessory)
    withExtendedLifetime(delegate) { app.run() }
}
