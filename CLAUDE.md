# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Proje Özeti

YouTube playlist URL'lerinden video bağlantılarını çıkaran native macOS menu bar uygulaması. Swift + SwiftUI + AppKit ile yazılmış, Dock'ta görünmez, popover arayüzü ile çalışır. Login'de otomatik başlatma desteği (SMAppService).

## Komutlar

```bash
# Makefile hedefleri
make build            # Debug build (swift build)
make release          # Release build
make run              # Debug modda çalıştır
make test             # Tüm testleri çalıştır (swift test)
make package          # macOS .app bundle oluştur
make install          # /Applications'a kur
make clean            # Temizle

# Doğrudan komutlar
swift build           # Derle
swift test            # Testleri çalıştır
swift test --filter ParserTests     # Sadece parser testleri
swift test --filter FetcherTests    # Sadece fetcher testleri
```

## Mimari

```
Sources/YouTubeExtractor/main.swift           → Uygulama giriş noktası
Sources/YouTubeExtractorLib/
  App.swift                                    → NSApplication başlatma (accessory policy)
  AppDelegate.swift                            → NSStatusItem + NSPopover yönetimi
  PopoverView.swift                            → SwiftUI ana arayüz
  ExtractorViewModel.swift                     → @MainActor ViewModel (async/await)
  YouTubeFetcher.swift                         → URLSession ile HTML çekme + URL doğrulama
  PlaylistParser.swift                         → ytInitialData JSON ayrıştırma
  LaunchAtLogin.swift                          → SMAppService wrapper
Tests/YouTubeExtractorTests/
  ParserTests.swift                            → Parser birim testleri (11 test)
  FetcherTests.swift                           → Fetcher URL doğrulama testleri (10 test)
```

**SPM yapısı:** `YouTubeExtractorLib` (library target) + `YouTubeExtractor` (executable) + `YouTubeExtractorTests` ayrımı — library'nin `@testable import` ile test edilebilmesi için.

**Veri akışı:** URL → `YouTubeFetcher.validateURL()` → `YouTubeFetcher.fetchHTML()` (async) → `PlaylistParser.extractVideoIDs()` → ViewModel @Published güncelleme → SwiftUI render

**Ayrıştırma stratejisi:** Go versiyonunun birebir Swift portu — `ytInitialData` marker arama → süslü parantez sayarak dengeli JSON çıkarma (`sliceBalancedJSON`) → NSRegularExpression ile video ID toplama → Set ile deduplicate.

### UI Kalıpları

- **Menu bar:** `NSStatusItem` + SF Symbol ikon (`play.rectangle.fill`)
- **Popover:** `NSPopover` (.transient) + `NSHostingController` ile SwiftUI embed
- **Concurrency:** `@MainActor` ViewModel, `Task` ile async/await, `Task.cancel()` ile iptal
- **Login başlatma:** `SMAppService.mainApp.register()` (macOS 13+)
- **Dock gizleme:** `NSApp.setActivationPolicy(.accessory)` + Info.plist `LSUIElement=true`

## Konvansiyonlar

- Kod yorumları ve hata mesajları Türkçe
- UI metinleri Türkçe ("Çıkar", "Panodan Al", "Tümünü Kopyala", "Dosyaya Kaydet")
- Hatalar enum-based error types (`ParserError`, `FetcherError`) ile `LocalizedError` uyumlu
- SSRF koruması: HTTPS zorunlu, YouTube domain kontrolü, `list=` param zorunlu
- Yanıt boyutu sınırı: 10 MB

## Platform

macOS 13+ (Ventura), Swift 5.10+, SPM
