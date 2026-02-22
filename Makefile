.PHONY: build release run test package install clean

APP_NAME = YouTube URL Extractor
BINARY_NAME = YouTubeExtractor

# Debug build
build:
	swift build

# Release build
release:
	swift build -c release

# Debug modda çalıştır
run: build
	.build/debug/$(BINARY_NAME)

# Testleri çalıştır
test:
	swift test

# macOS .app bundle oluştur
package: release
	mkdir -p "$(APP_NAME).app/Contents/MacOS"
	mkdir -p "$(APP_NAME).app/Contents/Resources"
	cp .build/release/$(BINARY_NAME) "$(APP_NAME).app/Contents/MacOS/$(BINARY_NAME)"
	cp Resources/Info.plist "$(APP_NAME).app/Contents/Info.plist"
	codesign --force --sign - "$(APP_NAME).app"

# /Applications'a kur
install: package
	cp -r "$(APP_NAME).app" "/Applications/$(APP_NAME).app"

# Temizle
clean:
	swift package clean
	rm -rf "$(APP_NAME).app"
	rm -rf .build
