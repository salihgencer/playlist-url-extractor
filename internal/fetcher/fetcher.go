package fetcher

import (
	"context"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"
)

const (
	userAgent = "Mozilla/5.0 (compatible; YouTubePlaylistExtractor/1.0)"
	// maxBodySize yanıt gövdesi için üst sınır (10 MB)
	maxBodySize = 10 * 1024 * 1024
	// maxRedirects izin verilen maksimum yönlendirme sayısı
	maxRedirects = 3
)

// defaultClient tüm istekler için yeniden kullanılan HTTP istemcisi.
// Her çağrıda yeni client oluşturmak connection pool ve TLS cache'i sıfırlar.
var defaultClient = &http.Client{
	Timeout: 15 * time.Second,
	CheckRedirect: func(req *http.Request, via []*http.Request) error {
		if len(via) >= maxRedirects {
			return fmt.Errorf("çok fazla yönlendirme (%d)", maxRedirects)
		}
		// Yönlendirme sonrası YouTube domain'inde kalındığını doğrula
		host := req.URL.Hostname()
		if !isYouTubeHost(host) {
			return fmt.Errorf("yönlendirme YouTube dışına çıkıyor: %s", host)
		}
		return nil
	},
}

// FetchHTML verilen URL'den HTML içerik metnini döndürür.
// Context ile iptal edilebilir; yanıt boyutu maxBodySize ile sınırlıdır.
func FetchHTML(ctx context.Context, url string) (string, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return "", fmt.Errorf("istek hazırlanamadı: %w", err)
	}
	req.Header.Set("User-Agent", userAgent)

	resp, err := defaultClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("istek gönderilemedi: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return "", fmt.Errorf("beklenmeyen durum kodu: %d", resp.StatusCode)
	}

	body, err := io.ReadAll(io.LimitReader(resp.Body, maxBodySize))
	if err != nil {
		return "", fmt.Errorf("gövde okunamadı: %w", err)
	}

	return string(body), nil
}

// ValidateURL YouTube playlist URL'sinin geçerliliğini doğrular.
// Sadece HTTPS şeması, YouTube domain'leri ve playlist parametresi kabul edilir.
func ValidateURL(rawURL string) error {
	if strings.TrimSpace(rawURL) == "" {
		return errors.New("URL boş olamaz")
	}

	parsed, err := url.Parse(rawURL)
	if err != nil {
		return fmt.Errorf("geçersiz URL formatı: %w", err)
	}

	// Sadece HTTPS kabul et — HTTP, file://, ftp:// gibi şemaları engelle (SSRF koruması)
	if parsed.Scheme != "https" {
		return fmt.Errorf("yalnızca HTTPS desteklenir, verilen: %s", parsed.Scheme)
	}

	if !isYouTubeHost(parsed.Hostname()) {
		return fmt.Errorf("yalnızca YouTube URL'leri desteklenir, verilen host: %s", parsed.Hostname())
	}

	// Playlist parametresi kontrolü — "list=" query param'ı zorunlu
	if parsed.Query().Get("list") == "" {
		return errors.New("URL bir playlist parametresi (list=...) içermelidir")
	}

	return nil
}

// isYouTubeHost verilen hostname'in YouTube'a ait olup olmadığını kontrol eder.
func isYouTubeHost(host string) bool {
	host = strings.ToLower(host)
	return host == "youtube.com" ||
		host == "www.youtube.com" ||
		host == "m.youtube.com" ||
		strings.HasSuffix(host, ".youtube.com") ||
		host == "youtu.be"
}
