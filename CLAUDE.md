# CLAUDE.md

Bu dosya bu repoda çalışan Claude Code oturumları içindir.

## Proje Özeti

Playlist URL Extractor: herkese açık bir oynatma listesindeki video bağlantılarını listeleyen native macOS menü çubuğu uygulaması (Mac App Store, `com.salihgencer.PlaylistURLExtractor`, takım A6R928V6HS). Swift + SwiftUI + AppKit; Dock'ta görünmez (LSUIElement), popover arayüzü.

Veri kaynağı resmi YouTube Data API v3'tür; uygulama `proxy/` altındaki Cloudflare Worker'ı çağırır, API anahtarı yalnız Worker'da (`YT_API_KEY` secret). HTML kazıma YOK ve geri getirilmemeli (App Review 5.2.x).

## Komutlar

```bash
swift test                          # Swift testleri (tümü temiz olmalı)
swift run PlaylistURLExtractorDev   # geliştirme çalıştırma
make xcode                          # xcodegen generate (.xcodeproj git'te yok)
make archive                        # App Store arşivi
make screenshots                    # 2880x1800 en/tr ekran görüntüleri (DEBUG derleme, örnek veri)
make strings                        # scripts/gen_strings.py → Localizable.xcstrings
cd proxy && npm ci && npm run check # Worker: tsc + vitest + wrangler dry-run
```

## Mimari

```
App/main.swift                      Xcode hedefinin girişi → startApp()
Sources/PlaylistURLExtractorKit/
  App.swift, AppDelegate.swift      NSStatusItem + NSPopover; ilk açılışta popover kendiliğinden açılır
  PopoverView.swift                 SwiftUI arayüz (metinler Text(_, bundle: .module))
  ExtractorViewModel.swift          @MainActor durum; PlaylistSource'u koordine eder
  PlaylistInput.swift               bağlantı/ID → playlist ID (ağ yok)
  PlaylistSource.swift              protokol + sayfalama (fetchPlaylist)
  ProxyPlaylistSource.swift         Worker istemcisi; hata kodu → PlaylistError
  SamplePlaylistSource.swift        ağsız sahte kaynak (testler, ekran görüntüleri)
  PlaylistError.swift               kullanıcıya gösterilen hatalar (en/tr)
  ScreenshotRenderer.swift          yalnız DEBUG: -RenderScreenshots <klasör>
  Resources/Localizable.xcstrings   scripts/gen_strings.py ile üretilir
proxy/src/index.ts                  GET /playlist-url-extractor/playlist?id=&pageToken=
```

Worker hata kodları (`PLAYLIST_NOT_FOUND`, `PLAYLIST_PRIVATE`, `PLAYLIST_UNSUPPORTED`, `INVALID_ID`, `QUOTA_EXCEEDED`, `RATE_LIMITED`, `UPSTREAM_ERROR`) ile `ProxyPlaylistSource.map(status:code:)` birlikte değişir.

## Konvansiyonlar

- Kod yorumları Türkçe; UI kaynak dili İngilizce, Türkçe çeviri String Catalog'da. Yeni metin → `scripts/gen_strings.py`'ye ekle, `make strings`; `LocalizationTests` eksik çeviriyi yakalar.
- Ad her yerde "Playlist URL Extractor". Ad, ikon, menü simgesi ve renklerde YouTube markası/kırmızı/oynat üçgeni kullanılmaz; "YouTube" yalnız atıf ve bağlantılarda geçer.
- Sürüm `project.yml` içinde (`MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`).
- Commit mesajları Türkçe, conventional commits.

## Platform

macOS 13+, Swift 5.10+ (SwiftPM) + xcodegen, Node 22 (proxy).
