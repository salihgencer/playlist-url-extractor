package main

import (
	_ "embed"
	"fmt"
	"strings"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/app"
	"fyne.io/fyne/v2/canvas"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/dialog"
	"fyne.io/fyne/v2/driver/desktop"
	"fyne.io/fyne/v2/layout"
	"fyne.io/fyne/v2/storage"
	"fyne.io/fyne/v2/theme"
	"fyne.io/fyne/v2/widget"
	"image/color"

	"youtube-url-extractor/internal/fetcher"
	"youtube-url-extractor/internal/parser"
)

//go:embed icon.png
var iconBytes []byte

func main() {
	a := app.NewWithID("com.youtube-extractor.app")
	icon := fyne.NewStaticResource("icon.png", iconBytes)
	a.SetIcon(icon)

	w := a.NewWindow("YouTube URL Extractor")
	w.Resize(fyne.NewSize(550, 500))

	// --- System Tray ---
	if desk, ok := a.(desktop.App); ok {
		desk.SetSystemTrayIcon(icon)
		desk.SetSystemTrayMenu(fyne.NewMenu("YouTube URL Extractor",
			fyne.NewMenuItem("Göster", func() {
				w.Show()
			}),
			fyne.NewMenuItemSeparator(),
			fyne.NewMenuItem("Çıkış", func() {
				a.Quit()
			}),
		))
	}

	// Pencere kapatılınca gizle, uygulamayı sonlandırma
	w.SetCloseIntercept(func() {
		w.Hide()
	})

	// --- Durum bilgisi ---
	var videoURLs []string

	// --- UI bileşenleri ---

	// URL giriş alanı
	urlEntry := widget.NewEntry()
	urlEntry.SetPlaceHolder("YouTube Playlist URL'sini yapıştır...")

	// Durum etiketi
	statusLabel := canvas.NewText("", color.NRGBA{R: 100, G: 100, B: 100, A: 255})
	statusLabel.TextSize = 12

	// Sonuç listesi
	list := widget.NewList(
		func() int {
			return len(videoURLs)
		},
		func() fyne.CanvasObject {
			return widget.NewLabel("")
		},
		func(id widget.ListItemID, obj fyne.CanvasObject) {
			obj.(*widget.Label).SetText(videoURLs[id])
		},
	)

	// Durum güncelleme yardımcıları
	setStatus := func(msg string, isError bool) {
		if isError {
			statusLabel.Color = color.NRGBA{R: 220, G: 50, B: 50, A: 255}
		} else {
			statusLabel.Color = color.NRGBA{R: 50, G: 150, B: 50, A: 255}
		}
		statusLabel.Text = msg
		statusLabel.Refresh()
	}

	// "Panodan Al" butonu
	pasteBtn := widget.NewButtonWithIcon("Panodan Al", theme.ContentPasteIcon(), func() {
		content := w.Clipboard().Content()
		if content != "" {
			urlEntry.SetText(content)
		}
	})

	// Alt butonlar (başlangıçta gizli olacak)
	copyAllBtn := widget.NewButtonWithIcon("Tümünü Kopyala", theme.ContentCopyIcon(), nil)
	saveBtn := widget.NewButtonWithIcon("Dosyaya Kaydet", theme.DocumentSaveIcon(), nil)
	bottomBar := container.NewHBox(copyAllBtn, saveBtn)
	bottomBar.Hide()

	// "Tümünü Kopyala" işlevi
	copyAllBtn.OnTapped = func() {
		if len(videoURLs) == 0 {
			return
		}
		w.Clipboard().SetContent(strings.Join(videoURLs, "\n"))
		setStatus(fmt.Sprintf("%d URL panoya kopyalandı", len(videoURLs)), false)
	}

	// "Dosyaya Kaydet" işlevi
	saveBtn.OnTapped = func() {
		if len(videoURLs) == 0 {
			return
		}
		d := dialog.NewFileSave(func(writer fyne.URIWriteCloser, err error) {
			if err != nil {
				setStatus("Dosya kaydedilemedi: "+err.Error(), true)
				return
			}
			if writer == nil {
				return // kullanıcı iptal etti
			}
			defer writer.Close()
			content := strings.Join(videoURLs, "\n") + "\n"
			if _, err := writer.Write([]byte(content)); err != nil {
				setStatus("Yazma hatası: "+err.Error(), true)
				return
			}
			setStatus("Dosya başarıyla kaydedildi", false)
		}, w)
		d.SetFilter(storage.NewExtensionFileFilter([]string{".txt"}))
		d.SetFileName("youtube-urls.txt")
		d.Show()
	}

	// "Çıkar" butonu
	extractBtn := widget.NewButton("Çıkar", nil)
	extractBtn.Importance = widget.HighImportance

	extractBtn.OnTapped = func() {
		url := strings.TrimSpace(urlEntry.Text)
		if url == "" {
			setStatus("Lütfen bir URL girin", true)
			return
		}

		// UI'ı "çalışıyor" durumuna getir
		extractBtn.Disable()
		setStatus("Video URL'leri çıkarılıyor...", false)
		statusLabel.Color = color.NRGBA{R: 100, G: 100, B: 100, A: 255}
		statusLabel.Refresh()
		bottomBar.Hide()

		go func() {
			html, err := fetcher.FetchHTML(url)
			if err != nil {
				fyne.Do(func() {
					setStatus("HTML alınamadı: "+err.Error(), true)
					extractBtn.Enable()
				})
				return
			}

			ids, err := parser.ExtractVideoIDs(html)
			if err != nil {
				fyne.Do(func() {
					setStatus("Video bulunamadı: "+err.Error(), true)
					extractBtn.Enable()
				})
				return
			}

			urls := make([]string, len(ids))
			for i, id := range ids {
				urls[i] = "https://www.youtube.com/watch?v=" + id
			}

			fyne.Do(func() {
				videoURLs = urls
				list.Refresh()
				setStatus(fmt.Sprintf("%d video URL'si bulundu", len(urls)), false)
				extractBtn.Enable()
				bottomBar.Show()
			})
		}()
	}

	// --- Düzen ---
	// Üst satır: URL giriş + Panodan Al
	topRow := container.NewBorder(nil, nil, nil, pasteBtn, urlEntry)

	// Ana düzen
	content := container.NewBorder(
		// Üst: URL giriş, çıkar butonu, durum
		container.NewVBox(
			topRow,
			extractBtn,
			container.NewHBox(layout.NewSpacer(), statusLabel, layout.NewSpacer()),
		),
		// Alt: Kopyala + Kaydet butonları
		bottomBar,
		nil, nil,
		// Orta: Sonuç listesi
		list,
	)

	w.SetContent(content)
	w.ShowAndRun()
}
