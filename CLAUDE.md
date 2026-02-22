# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Proje Özeti

YouTube playlist URL'lerinden video bağlantılarını çıkaran Go projesi. İki arayüz sunar:
- **CLI aracı** (`cmd/playlist`) — sıfır harici bağımlılık, sadece Go standart kütüphanesi
- **macOS menu bar uygulaması** (`cmd/app`) — Fyne v2.7.2 GUI framework ile system tray entegrasyonu

## Komutlar

```bash
# Makefile hedefleri (önerilen yol)
make cli              # CLI aracını derle → ./youtube-extractor
make app              # Menu bar uygulamasını derle → ./YouTubeExtractor
make package          # macOS .app bundle oluştur (fyne CLI gerekir)
make test             # Tüm testleri çalıştır
make clean            # Derleme çıktılarını temizle

# Doğrudan çalıştırma
go run ./cmd/playlist "https://www.youtube.com/playlist?list=PLAYLIST_ID"
go run ./cmd/app      # GUI uygulamasını başlat

# Tek paketteki testleri çalıştır
go test ./internal/parser/
```

## Mimari

```
cmd/playlist/main.go        → CLI giriş noktası (flag parsing, stdout çıktı)
cmd/app/main.go             → Fyne GUI uygulaması (system tray, pencere yönetimi)
cmd/app/icon.png             → Gömülü uygulama ikonu (//go:embed)
internal/fetcher/fetcher.go  → HTTP ile YouTube HTML sayfasını çeker
internal/parser/parser.go    → ytInitialData JSON'dan video ID'leri çıkarır
assets/icon.png              → Uygulama ikonu (paketleme için)
FyneApp.toml                 → Fyne uygulama metadata (ID, versiyon, ikon)
```

**Veri akışı (her iki arayüz):** URL → `fetcher.FetchHTML(url)` → `parser.ExtractVideoIDs(html)` → video URL listesi

**Ayrıştırma stratejisi:** YouTube'un karmaşık JSON yapısını unmarshal etmek yerine, `ytInitialData` JavaScript nesnesini string arama ile bulur, süslü parantez sayarak dengeli JSON çıkarır (`sliceBalancedJSON`), sonra regex ile video ID'leri toplar.

### GUI Uygulaması Kalıpları

- **System tray:** `desktop.App` arayüzü ile tray ikonu ve menüsü. Pencere kapatılınca gizlenir (`SetCloseIntercept`), uygulama arka planda çalışmaya devam eder.
- **Goroutine → UI:** Ağ çağrıları goroutine içinde yapılır, UI güncellemeleri `fyne.Do()` ile ana thread'e marshal edilir.
- **İkon gömme:** `//go:embed icon.png` ile binary'ye gömülür, `fyne.NewStaticResource` ile kullanılır.

## Konvansiyonlar

- Kod yorumları ve hata mesajları Türkçe
- UI metinleri Türkçe ("Çıkar", "Panodan Al", "Tümünü Kopyala", "Dosyaya Kaydet")
- Go standart proje düzeni: `cmd/` (giriş noktaları), `internal/` (dışarıya kapalı paketler)
- Hatalar `fmt.Errorf("bağlam: %w", err)` ile sarmalanır
- Video ID regex deseni: `"videoId":"([a-zA-Z0-9_-]+)"`
- Video ID'ler `map[string]struct{}` ile tekilleştirilir

## Go Sürümü

Go 1.25.2 — Fyne v2.7.2 (`go.mod`'da tanımlı)
