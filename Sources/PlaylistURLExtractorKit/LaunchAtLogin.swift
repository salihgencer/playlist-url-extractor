import ServiceManagement

/// Girişte otomatik başlatma (SMAppService, macOS 13+). Varsayılan kapalı; yalnız kullanıcı açar.
public enum LaunchAtLogin {
    public static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("Login öğesi ayarlanamadı: \(error.localizedDescription)")
        }
    }

    public static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }
}
