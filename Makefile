.PHONY: build test run xcode archive screenshots icon strings proxy-test clean

SCHEME = PlaylistURLExtractor
DERIVED = .build/xcode
ARCHIVE = .build/PlaylistURLExtractor.xcarchive

# Swift paketi (geliştirme)
build:
	swift build

test:
	swift test

run:
	swift run PlaylistURLExtractorDev

# Xcode projesini üret (xcodegen; .xcodeproj git'e girmez)
xcode:
	xcodegen generate

# App Store arşivi (imzalı; Xcode'da A6R928V6HS hesabı gerekir)
archive: xcode
	xcodebuild archive -project $(SCHEME).xcodeproj -scheme $(SCHEME) -configuration Release \
		-archivePath $(ARCHIVE) -derivedDataPath $(DERIVED)

# 2880x1800 App Store ekran görüntüleri (DEBUG derleme, ağsız örnek veri) → docs/appstore/screenshots
screenshots: xcode
	xcodebuild build -project $(SCHEME).xcodeproj -scheme $(SCHEME) -configuration Debug \
		-derivedDataPath $(DERIVED) CODE_SIGNING_ALLOWED=NO
	for l in en tr; do \
		"$(DERIVED)/Build/Products/Debug/Playlist URL Extractor.app/Contents/MacOS/Playlist URL Extractor" \
			-RenderScreenshots "$(CURDIR)/docs/appstore/screenshots" -AppleLanguages "($$l)" -AppleLocale $$l; \
	done

icon:
	swift scripts/make_icon.swift

strings:
	python3 scripts/gen_strings.py

proxy-test:
	cd proxy && npm ci && npm run check

clean:
	swift package clean
	rm -rf .build $(SCHEME).xcodeproj
