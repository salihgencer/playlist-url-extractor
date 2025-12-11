package parser

import (
	"errors"
	"fmt"
	"regexp"
	"strings"
)

var (
	videoIDRegex       = regexp.MustCompile(`"videoId":"([a-zA-Z0-9_-]+)"`)
	initialDataMarkers = []string{
		"var ytInitialData",
		"window[\"ytInitialData\"]",
		"ytInitialData",
	}
)

// ExtractVideoIDs YouTube playlist HTML'inden video ID listesini üretir.
func ExtractVideoIDs(html string) ([]string, error) {
	jsonPayload, err := extractInitialDataJSON(html)
	if err != nil {
		return nil, err
	}

	matches := videoIDRegex.FindAllStringSubmatch(jsonPayload, -1)
	if len(matches) == 0 {
		return nil, errors.New("video ID bulunamadı")
	}

	seen := make(map[string]struct{})
	ids := make([]string, 0, len(matches))

	for _, match := range matches {
		if len(match) < 2 {
			continue
		}
		id := match[1]
		if _, ok := seen[id]; ok {
			continue
		}
		seen[id] = struct{}{}
		ids = append(ids, id)
	}

	return ids, nil
}

func extractInitialDataJSON(html string) (string, error) {
	for _, marker := range initialDataMarkers {
		idx := strings.Index(html, marker)
		if idx == -1 {
			continue
		}

		after := html[idx:]
		start := strings.Index(after, "{")
		if start == -1 {
			continue
		}

		jsonPayload, err := sliceBalancedJSON(after[start:])
		if err == nil {
			return jsonPayload, nil
		}
	}

	return "", errors.New("ytInitialData bulunamadı")
}

func sliceBalancedJSON(payload string) (string, error) {
	var (
		builder    strings.Builder
		inString   bool
		escape     bool
		braceCount int
	)

	for i := 0; i < len(payload); i++ {
		ch := payload[i]
		builder.WriteByte(ch)

		if escape {
			escape = false
			continue
		}

		switch ch {
		case '\\':
			escape = true
			continue
		case '"':
			inString = !inString
			continue
		}

		if inString {
			continue
		}

		switch ch {
		case '{':
			braceCount++
		case '}':
			braceCount--
			if braceCount == 0 {
				return builder.String(), nil
			}
		}
	}

	return "", fmt.Errorf("ytInitialData JSON kapanışı bulunamadı")
}
