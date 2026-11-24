import Foundation

/// Uygulama içi bağlantılar. YouTube API Hizmetleri Geliştirici Politikaları (III.A.1, III.A.2)
/// YouTube Hizmet Şartları ve Google Gizlilik Politikası bağlantılarının gösterilmesini ister.
enum ExternalLinks {
    static let youTubeTerms = URL(string: "https://www.youtube.com/t/terms")!
    static let googlePrivacy = URL(string: "https://policies.google.com/privacy")!

    static var privacyPolicy: URL {
        isTurkish
            ? URL(string: "https://salihgencer.com/playlist-url-extractor/gizlilik/")!
            : URL(string: "https://salihgencer.com/playlist-url-extractor/privacy/")!
    }

    static var support: URL {
        isTurkish
            ? URL(string: "https://salihgencer.com/playlist-url-extractor/destek/")!
            : URL(string: "https://salihgencer.com/playlist-url-extractor/support/")!
    }

    private static var isTurkish: Bool {
        L10n.bundle.preferredLocalizations.first == "tr"
    }
}
