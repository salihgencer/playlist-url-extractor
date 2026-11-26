import Foundation

/// Yerelleştirilmiş metinlerin bulunduğu kaynak paketi (String Catalog: Resources/Localizable.xcstrings).
enum L10n {
    static var bundle: Bundle { .module }

    /// Bundle.module içindeki String Catalog'dan yerelleştirilmiş metin döndürür.
    static func string(_ key: String.LocalizationValue) -> String {
        String(localized: key, bundle: .module)
    }
}
