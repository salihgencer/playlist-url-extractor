import ServiceManagement

/// macOS giriş'te otomatik başlatma yöneticisi.
/// SMAppService (macOS 13+) kullanır — eski LaunchAgent yöntemine gerek yok.
public enum LaunchAtLogin {
    /// Login öğesini etkinleştirir veya devre dışı bırakır
    public static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Login öğesi ayarlanamadı: \(error)")
        }
    }

    /// Login öğesinin aktif olup olmadığını döndürür
    public static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }
}
