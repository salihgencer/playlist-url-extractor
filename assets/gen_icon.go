//go:build ignore

// Bu dosya menu bar ikonu oluşturmak için bir kerelik çalıştırılır.
// go run assets/gen_icon.go
package main

import (
	"image"
	"image/color"
	"image/png"
	"os"
)

func main() {
	const size = 22
	img := image.NewNRGBA(image.Rect(0, 0, size, size))

	// Saydam arka plan (zaten sıfır değer = tamamen saydam)

	// Play butonu üçgeni çiz (macOS template image: siyah piksel + alfa)
	black := color.NRGBA{R: 0, G: 0, B: 0, A: 255}

	// Üçgen köşeleri: sol(5,3) sağ(18,11) alt-sol(5,19)
	// Her satır için x aralığını hesapla
	for y := 3; y <= 19; y++ {
		// Üçgenin sol kenarı sabit x=5
		// Sağ kenar: y=3'te x=5, y=11'de x=18, y=19'da x=5
		// Üst yarı (y: 3-11): xRight = 5 + (y-3) * 13 / 8
		// Alt yarı (y: 11-19): xRight = 18 - (y-11) * 13 / 8
		var xRight int
		if y <= 11 {
			xRight = 5 + (y-3)*13/8
		} else {
			xRight = 18 - (y-11)*13/8
		}
		for x := 5; x <= xRight; x++ {
			img.Set(x, y, black)
		}
	}

	f, err := os.Create("assets/icon.png")
	if err != nil {
		panic(err)
	}
	defer f.Close()

	if err := png.Encode(f, img); err != nil {
		panic(err)
	}
}
