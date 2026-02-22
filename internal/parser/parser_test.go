package parser

import (
	"strings"
	"testing"
)

const sampleHTML = `
<html>
<body>
<script>
var ytInitialData = {"contents":{"playlistVideoListRenderer":{"contents":[{"playlistVideoRenderer":{"videoId":"abc123def45"}},{"playlistVideoRenderer":{"videoId":"xyz987uvw65"}},{"playlistVideoRenderer":{"videoId":"abc123def45"}}]}}};
</script>
</body>
</html>`

func TestExtractVideoIDs(t *testing.T) {
	ids, err := ExtractVideoIDs(sampleHTML)
	if err != nil {
		t.Fatalf("hata beklenmiyordu: %v", err)
	}

	expected := []string{"abc123def45", "xyz987uvw65"}

	if len(ids) != len(expected) {
		t.Fatalf("beklenen uzunluk %d, gelen %d (ids=%v)", len(expected), len(ids), ids)
	}

	if strings.Join(ids, ",") != strings.Join(expected, ",") {
		t.Fatalf("beklenen %v, gelen %v", expected, ids)
	}
}

func TestExtractVideoIDs_BoşHTML(t *testing.T) {
	_, err := ExtractVideoIDs("")
	if err == nil {
		t.Fatal("boş HTML için hata bekleniyor")
	}
}

func TestExtractVideoIDs_MarkerYok(t *testing.T) {
	_, err := ExtractVideoIDs("<html><body><script>var x = 1;</script></body></html>")
	if err == nil {
		t.Fatal("ytInitialData yokken hata bekleniyor")
	}
}

func TestExtractVideoIDs_VideoIDYok(t *testing.T) {
	// ytInitialData var ama içinde videoId yok
	html := `<script>var ytInitialData = {"contents":{"empty": true}};</script>`
	_, err := ExtractVideoIDs(html)
	if err == nil {
		t.Fatal("video ID yokken hata bekleniyor")
	}
}

func TestExtractVideoIDs_TekVideo(t *testing.T) {
	html := `<script>var ytInitialData = {"playlistVideoRenderer":{"videoId":"single12345"}};</script>`
	ids, err := ExtractVideoIDs(html)
	if err != nil {
		t.Fatalf("hata beklenmiyordu: %v", err)
	}
	if len(ids) != 1 || ids[0] != "single12345" {
		t.Fatalf("beklenen [single12345], gelen %v", ids)
	}
}

func TestExtractVideoIDs_WindowMarker(t *testing.T) {
	// İkinci marker formatı: window["ytInitialData"]
	html := `<script>window["ytInitialData"] = {"playlistVideoRenderer":{"videoId":"win_marker01"}};</script>`
	ids, err := ExtractVideoIDs(html)
	if err != nil {
		t.Fatalf("hata beklenmiyordu: %v", err)
	}
	if len(ids) != 1 || ids[0] != "win_marker01" {
		t.Fatalf("beklenen [win_marker01], gelen %v", ids)
	}
}

func TestExtractVideoIDs_EscapedQuotes(t *testing.T) {
	// JSON string içinde escaped tırnak — sliceBalancedJSON doğru handle etmeli
	html := `<script>var ytInitialData = {"title":"test \"quoted\"","videoId":"esc_quote_01"};</script>`
	ids, err := ExtractVideoIDs(html)
	if err != nil {
		t.Fatalf("hata beklenmiyordu: %v", err)
	}
	if len(ids) != 1 || ids[0] != "esc_quote_01" {
		t.Fatalf("beklenen [esc_quote_01], gelen %v", ids)
	}
}

func TestSliceBalancedJSON_KapanmamışJSON(t *testing.T) {
	_, err := sliceBalancedJSON(`{"key": "value"`)
	if err == nil {
		t.Fatal("kapanmamış JSON için hata bekleniyor")
	}
}

func TestSliceBalancedJSON_FazladanKapanış(t *testing.T) {
	_, err := sliceBalancedJSON(`}{"key": "value"}`)
	if err == nil {
		t.Fatal("fazladan kapanış parantezi için hata bekleniyor")
	}
	if !strings.Contains(err.Error(), "fazladan kapanış parantezi") {
		t.Fatalf("beklenen hata mesajı 'fazladan kapanış parantezi' içermeli, gelen: %s", err.Error())
	}
}

func TestSliceBalancedJSON_İçİçeJSON(t *testing.T) {
	input := `{"a":{"b":{"c":"d"}},"e":"f"} garbage after`
	result, err := sliceBalancedJSON(input)
	if err != nil {
		t.Fatalf("hata beklenmiyordu: %v", err)
	}
	expected := `{"a":{"b":{"c":"d"}},"e":"f"}`
	if result != expected {
		t.Fatalf("beklenen %s, gelen %s", expected, result)
	}
}

func TestSliceBalancedJSON_StringİçindeSüslüParantez(t *testing.T) {
	// String içindeki { ve } karakterleri sayılmamalı
	input := `{"key":"value with { and } inside"}`
	result, err := sliceBalancedJSON(input)
	if err != nil {
		t.Fatalf("hata beklenmiyordu: %v", err)
	}
	if result != input {
		t.Fatalf("beklenen %s, gelen %s", input, result)
	}
}
