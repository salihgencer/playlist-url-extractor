# Swift macOS Menu Bar App Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Go/Fyne uygulamasını native Swift macOS menu bar uygulamasına dönüştür. Dock'ta görünmez, popover ile çalışır, login'de otomatik başlar.

**Architecture:** NSStatusItem + NSPopover + SwiftUI. Logic katmanı (fetcher, parser) Swift'e port edilir. Library target ile testlenebilir yapı. SMAppService ile login'de başlatma.

**Tech Stack:** Swift 5.10+, SwiftUI, AppKit, URLSession (async/await), SMAppService, SPM

---

### Task 1: Proje İskeleti

**Files:**
- Create: `Package.swift`
- Create: `Sources/YouTubeExtractor/main.swift`
- Create: `Sources/YouTubeExtractorLib/App.swift`
- Create: `Resources/Info.plist`
- Create: `Makefile` (yeni, Go yerine Swift)

**Step 1: Package.swift oluştur**

SPM manifest — library + executable + test target ayrımı (testable import için).

**Step 2: main.swift — minimal entry point**

`YouTubeExtractorLib.startApp()` çağrısı.

**Step 3: App.swift — NSApplication başlatma**

`startApp()` public fonksiyonu: NSApplication.shared + accessory activation policy.

**Step 4: Info.plist — LSUIElement=true**

Dock'ta görünmez. Bundle metadata.

**Step 5: Makefile — build/test/package/install**

`swift build`, `swift test`, .app bundle oluşturma, `/Applications` kurulumu.

**Step 6: Build doğrula**

`swift build` başarılı olmalı (boş pencere, sadece menu bar ikonu).

**Step 7: Commit**

---

### Task 2: PlaylistParser (TDD)

**Files:**
- Create: `Sources/YouTubeExtractorLib/PlaylistParser.swift`
- Create: `Tests/YouTubeExtractorTests/ParserTests.swift`

**Step 1: Test yaz** — happy path, boş HTML, marker yok, bozuk JSON, tek video, escaped quotes, iç içe JSON

**Step 2: Testi çalıştır, FAIL olduğunu doğrula**

**Step 3: PlaylistParser implement et** — Go parser'ın birebir Swift portu: marker arama → sliceBalancedJSON → regex match → dedup

**Step 4: Testi çalıştır, PASS olduğunu doğrula**

**Step 5: Commit**

---

### Task 3: YouTubeFetcher (TDD)

**Files:**
- Create: `Sources/YouTubeExtractorLib/YouTubeFetcher.swift`
- Create: `Tests/YouTubeExtractorTests/FetcherTests.swift`

**Step 1: ValidateURL testleri yaz** — geçerli playlist, boş URL, HTTP şeması, file://, YouTube dışı domain, list= parametresi yok

**Step 2: Testi çalıştır, FAIL**

**Step 3: YouTubeFetcher implement et** — validateURL (static), fetchHTML (async/await + URLSession)

**Step 4: Testi çalıştır, PASS**

**Step 5: Commit**

---

### Task 4: ExtractorViewModel

**Files:**
- Create: `Sources/YouTubeExtractorLib/ExtractorViewModel.swift`

**Step 1: @MainActor ViewModel** — @Published properties: urlText, videoURLs, statusMessage, isError, isLoading

**Step 2: extract() fonksiyonu** — Task ile async, cancellation desteği

**Step 3: pasteFromClipboard(), copyAll() fonksiyonları**

**Step 4: Build doğrula**

**Step 5: Commit**

---

### Task 5: UI — AppDelegate + PopoverView

**Files:**
- Create: `Sources/YouTubeExtractorLib/AppDelegate.swift`
- Create: `Sources/YouTubeExtractorLib/PopoverView.swift`

**Step 1: AppDelegate** — NSStatusItem (SF Symbol ikonu), NSPopover (.transient), toggle logic

**Step 2: PopoverView** — SwiftUI: başlık, URL giriş, çıkar butonu, sonuç listesi, kopyala/kaydet butonları, ayarlar menüsü

**Step 3: App.swift güncelle** — AppDelegate kullan

**Step 4: Build + manuel test** (`swift build && .build/debug/YouTubeExtractor`)

**Step 5: Commit**

---

### Task 6: Launch at Login

**Files:**
- Create: `Sources/YouTubeExtractorLib/LaunchAtLogin.swift`

**Step 1: SMAppService wrapper** — register/unregister, isEnabled

**Step 2: PopoverView'a toggle ekle** — @AppStorage ile persist

**Step 3: Build doğrula**

**Step 4: Commit**

---

### Task 7: Go Dosyalarını Kaldır + Config Güncelle

**Files:**
- Delete: `cmd/`, `internal/`, `go.mod`, `go.sum`, `FyneApp.toml`, `assets/`, `playlist_html_content.html`, `playlist`, `app`, `youtube-extractor`
- Update: `.gitignore`, `CLAUDE.md`, `README.md`

**Step 1: Go dosyalarını sil**

**Step 2: .gitignore güncelle** — Swift/.build artifacts

**Step 3: CLAUDE.md güncelle** — Swift mimarisi, yeni komutlar

**Step 4: README.md güncelle**

**Step 5: Commit**

---

### Task 8: Final Build + Package

**Step 1: `make test`** — tüm testler geçmeli

**Step 2: `make package`** — .app bundle oluşturulmalı

**Step 3: `make install`** — /Applications'a kurulmalı

**Step 4: Uygulamayı çalıştır ve manuel test et

**Step 5: Push**
