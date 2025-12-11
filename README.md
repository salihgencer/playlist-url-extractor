# YouTube URL Extractor

YouTube playlist URL'inden tüm video bağlantılarını çıkaran Go CLI aracı.

## Özellikler

- 🎬 YouTube playlist'lerinden video ID'lerini çıkarır
- 🔗 Tam video URL'lerini listeler
- 🚀 Hızlı ve bağımlılık gerektirmez (pure Go)
- ✅ Duplike video ID'lerini otomatik filtreler

## Gereksinimler

- Go 1.21 veya üzeri

## Kurulum

```bash
# Projeyi klonlayın
git clone <repository-url>
cd youtube-url-extractor

# Derleyin
go build -o youtube-extractor ./cmd/playlist
```

## Kullanım

```bash
# Playlist URL'i ile çalıştırın
./youtube-extractor "https://www.youtube.com/playlist?list=PLAYLIST_ID"
```

### Örnek Çıktı

```
https://www.youtube.com/watch?v=abc123def45
https://www.youtube.com/watch?v=xyz987uvw65
https://www.youtube.com/watch?v=qwe456rty78
```

### Doğrudan Çalıştırma (Derlemeden)

```bash
go run ./cmd/playlist "https://www.youtube.com/playlist?list=PLAYLIST_ID"
```

## Proje Yapısı

```
youtube-url-extractor/
├── cmd/
│   └── playlist/
│       └── main.go           # CLI giriş noktası
├── internal/
│   ├── fetcher/
│   │   └── fetcher.go        # HTTP istekleri ve HTML alma
│   └── parser/
│       ├── parser.go         # Video ID çıkarma mantığı
│       └── parser_test.go    # Birim testleri
├── go.mod
└── README.md
```

## Testleri Çalıştırma

```bash
go test ./...
```

## Nasıl Çalışır?

1. **Fetcher**: Verilen playlist URL'ine HTTP isteği gönderir
2. **Parser**: HTML içindeki `ytInitialData` JavaScript objesini bulur
3. **Extractor**: JSON verisi içinden `videoId` değerlerini regex ile çıkarır
4. **Dedup**: Tekrarlanan video ID'lerini filtreler ve sonucu listeler

## Lisans

MIT License
