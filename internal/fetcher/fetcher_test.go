package fetcher

import "testing"

func TestValidateURL_GeçerliPlaylist(t *testing.T) {
	err := ValidateURL("https://www.youtube.com/playlist?list=PLxxxxxxxx")
	if err != nil {
		t.Fatalf("geçerli URL için hata beklenmiyordu: %v", err)
	}
}

func TestValidateURL_GeçerliPlaylistEkParametreli(t *testing.T) {
	err := ValidateURL("https://www.youtube.com/watch?v=abc123&list=PLxxxxxxxx")
	if err != nil {
		t.Fatalf("geçerli URL için hata beklenmiyordu: %v", err)
	}
}

func TestValidateURL_BoşURL(t *testing.T) {
	err := ValidateURL("")
	if err == nil {
		t.Fatal("boş URL için hata bekleniyor")
	}
}

func TestValidateURL_HTTPŞeması(t *testing.T) {
	err := ValidateURL("http://www.youtube.com/playlist?list=PLxxxxxxxx")
	if err == nil {
		t.Fatal("HTTP şeması için hata bekleniyor")
	}
}

func TestValidateURL_FileŞeması(t *testing.T) {
	err := ValidateURL("file:///etc/passwd")
	if err == nil {
		t.Fatal("file:// şeması için hata bekleniyor (SSRF)")
	}
}

func TestValidateURL_YouTubeDışıDomain(t *testing.T) {
	err := ValidateURL("https://evil.com/playlist?list=PLxxxxxxxx")
	if err == nil {
		t.Fatal("YouTube dışı domain için hata bekleniyor")
	}
}

func TestValidateURL_Localhost(t *testing.T) {
	err := ValidateURL("https://localhost:8080/playlist?list=PLxxxxxxxx")
	if err == nil {
		t.Fatal("localhost için hata bekleniyor (SSRF)")
	}
}

func TestValidateURL_PlaylistParametresiYok(t *testing.T) {
	err := ValidateURL("https://www.youtube.com/watch?v=abc123")
	if err == nil {
		t.Fatal("list= parametresi olmayan URL için hata bekleniyor")
	}
}

func TestValidateURL_MobilYouTube(t *testing.T) {
	err := ValidateURL("https://m.youtube.com/playlist?list=PLxxxxxxxx")
	if err != nil {
		t.Fatalf("mobil YouTube URL'si geçerli olmalı: %v", err)
	}
}

func TestIsYouTubeHost(t *testing.T) {
	tests := []struct {
		host string
		want bool
	}{
		{"youtube.com", true},
		{"www.youtube.com", true},
		{"m.youtube.com", true},
		{"music.youtube.com", true},
		{"youtu.be", true},
		{"evil.com", false},
		{"notyoutube.com", false},
		{"youtube.com.evil.com", false},
		{"localhost", false},
	}

	for _, tt := range tests {
		got := isYouTubeHost(tt.host)
		if got != tt.want {
			t.Errorf("isYouTubeHost(%q) = %v, beklenen %v", tt.host, got, tt.want)
		}
	}
}
