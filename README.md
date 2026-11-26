# Playlist URL Extractor

Herkese açık bir oynatma listesindeki tüm video bağlantılarını listeleyen native macOS menü çubuğu uygulaması (Mac App Store, macOS 13+).

- Veri kaynağı: resmi **YouTube Data API v3** (`playlistItems.list`, sayfalama ile tüm öğeler). HTML kazıma yok.
- API anahtarı uygulamada **yok**: istekler `proxy/` altındaki Cloudflare Worker'dan geçer
  (`https://api.salihgencer.com/playlist-url-extractor/playlist?id=…`), anahtar Worker secret'ı `YT_API_KEY`.
- Video indirmez; yalnızca bağlantıları kopyalar veya `.txt` olarak kaydeder.
- İngilizce + Türkçe (String Catalog).

## Geliştirme

```bash
swift test                 # Swift birim testleri
swift run PlaylistURLExtractorDev   # geliştirme için menü çubuğu uygulaması
make xcode                 # xcodegen → PlaylistURLExtractor.xcodeproj (git'e girmez)
make archive               # imzalı App Store arşivi
make screenshots           # docs/appstore/screenshots (2880x1800, en+tr)
make icon                  # docs/appstore/icon-1024.png + App/Assets.xcassets/AppIcon
make strings               # Localizable.xcstrings'i scripts/gen_strings.py'den üret
make proxy-test            # Worker: typecheck + vitest + wrangler dry-run
```

## Yapı

```
App/                         Xcode uygulama hedefi (main.swift, Info.plist, entitlements, ikon, PrivacyInfo)
project.yml                  xcodegen tanımı (2.0.0 / build 4, sandbox, LSUIElement)
Sources/PlaylistURLExtractorKit/   Uygulama mantığı + SwiftUI arayüz (SwiftPM kütüphanesi)
Sources/PlaylistURLExtractorDev/   `swift run` girişi
Tests/PlaylistURLExtractorKitTests/
proxy/                       Cloudflare Worker (YouTube Data API vekili)
docs/appstore/               ASC metadata taslağı, ikon kaynağı, ekran görüntüleri
```

Bağımsız bir uygulamadır; YouTube veya Google ile bağlantılı değildir. MIT License.
