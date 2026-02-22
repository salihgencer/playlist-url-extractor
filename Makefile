.PHONY: cli app package clean test

# CLI aracını derle
cli:
	go build -o youtube-extractor ./cmd/playlist

# Menu bar uygulamasını derle
app:
	go build -o YouTubeExtractor ./cmd/app

# macOS .app bundle oluştur
package:
	fyne package -os darwin -icon assets/icon.png -name "YouTube URL Extractor" -sourceDir ./cmd/app

# Derleme çıktılarını temizle
clean:
	rm -f youtube-extractor YouTubeExtractor
	rm -rf "YouTube URL Extractor.app"

# Testleri çalıştır
test:
	go test ./...
