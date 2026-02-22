# YouTube URL Extractor

YouTube playlist URL'inden tüm video bağlantılarını çıkaran native macOS menu bar uygulaması.

## Özellikler

- macOS menu bar'da yaşar, Dock'ta görünmez
- Popover arayüzü ile hızlı erişim
- YouTube playlist'lerinden video URL'lerini çıkarır
- Tekrarlanan video ID'lerini otomatik filtreler
- Panoya kopyalama ve dosyaya kaydetme
- Giriş'te otomatik başlatma (SMAppService)
- SSRF korumalı URL doğrulama

## Gereksinimler

- macOS 13 (Ventura) veya üzeri
- Swift 5.10 veya üzeri

## Kurulum

```bash
# Projeyi klonlayın
git clone https://github.com/salihgencer/youtube-url-extractor.git
cd youtube-url-extractor

# Derleyin ve kurun
make install
```

Bu komut `.app` bundle oluşturur ve `/Applications`'a kopyalar.

## Geliştirme

```bash
# Debug build
make build

# Debug modda çalıştır
make run

# Testleri çalıştır
make test

# Release .app bundle oluştur
make package

# Temizle
make clean
```

## Nasıl Çalışır?

1. Menu bar'daki ikona tıklayın
2. YouTube playlist URL'sini yapıştırın (veya "Panodan Al" ile)
3. "Çıkar" butonuna tıklayın
4. Video URL'lerini kopyalayın veya dosyaya kaydedin

## Proje Yapısı

```
Sources/
├── YouTubeExtractor/main.swift          # Uygulama giriş noktası
└── YouTubeExtractorLib/
    ├── App.swift                        # NSApplication başlatma
    ├── AppDelegate.swift                # Menu bar + Popover
    ├── PopoverView.swift                # SwiftUI arayüz
    ├── ExtractorViewModel.swift         # İş mantığı
    ├── YouTubeFetcher.swift             # HTTP + URL doğrulama
    ├── PlaylistParser.swift             # YouTube HTML parser
    └── LaunchAtLogin.swift              # Login'de başlatma
Tests/
└── YouTubeExtractorTests/
    ├── ParserTests.swift                # 11 test
    └── FetcherTests.swift               # 10 test
```

## Lisans

MIT License
