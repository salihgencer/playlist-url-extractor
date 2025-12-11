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
