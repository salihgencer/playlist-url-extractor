import Cocoa

/// Uygulamayı başlatır. Dock'ta görünmez, sadece menu bar'da yaşar.
public func startApp() {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    // Dock ikonunu gizle — sadece menu bar uygulaması
    app.setActivationPolicy(.accessory)
    app.run()
}
