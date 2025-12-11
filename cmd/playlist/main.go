package main

import (
	"flag"
	"fmt"
	"log"
	"os"

	"youtube-url-extractor/internal/fetcher"
	"youtube-url-extractor/internal/parser"
)

func main() {
	log.SetFlags(0)
	flag.Usage = func() {
		fmt.Fprintf(flag.CommandLine.Output(), "Kullanım: %s <playlist-url>\n", os.Args[0])
		flag.PrintDefaults()
	}
	flag.Parse()

	if flag.NArg() < 1 {
		flag.Usage()
		os.Exit(1)
	}

	playlistURL := flag.Arg(0)

	html, err := fetcher.FetchHTML(playlistURL)
	if err != nil {
		log.Fatalf("HTML alınamadı: %v", err)
	}

	ids, err := parser.ExtractVideoIDs(html)
	if err != nil {
		log.Fatalf("Video ID'leri çıkarılamadı: %v", err)
	}

	for _, id := range ids {
		fmt.Printf("https://www.youtube.com/watch?v=%s\n", id)
	}
}
