#!/usr/bin/env python3
"""Localizable.xcstrings üretir (en kaynak + tr). Metin değiştirince bunu düzenleyip çalıştır:
    python3 scripts/gen_strings.py
"""
import json, pathlib

TR = {
    "Extract Links": "Bağlantıları Çıkar",
    "Cancel": "İptal",
    "Copy All": "Tümünü Kopyala",
    "Save as Text File…": "Metin Olarak Kaydet…",
    "Google Privacy Policy": "Google Gizlilik Politikası",
    "YouTube Terms of Service": "YouTube Hizmet Şartları",
    "Launch at Login": "Girişte Başlat",
    "Paste a public playlist link to list every video link in it.":
        "İçindeki tüm video bağlantılarını listelemek için herkese açık bir oynatma listesi bağlantısı yapıştırın.",
    "Paste from Clipboard": "Panodan Yapıştır",
    "Playlist link or ID": "Oynatma listesi bağlantısı veya kimliği",
    "Privacy Policy": "Gizlilik Politikası",
    "Quit Playlist URL Extractor": "Playlist URL Extractor'dan Çık",
    "Settings": "Ayarlar",
    "Support": "Destek",
    "Uses YouTube API Services. Not affiliated with YouTube or Google.":
        "YouTube API Hizmetlerini kullanır. YouTube veya Google ile bağlantılı değildir.",
    "Fetching playlist…": "Oynatma listesi alınıyor…",
    "File saved": "Dosya kaydedildi",
    "The file couldn't be saved.": "Dosya kaydedilemedi.",
    "This playlist has no available videos.": "Bu oynatma listesinde erişilebilir video yok.",
    "Paste a playlist link or ID first.": "Önce bir oynatma listesi bağlantısı veya kimliği yapıştırın.",
    "That doesn't look like a playlist link or ID.": "Bu bir oynatma listesi bağlantısı veya kimliği gibi görünmüyor.",
    "This link has no playlist in it. Use a link that contains “list=”.":
        "Bu bağlantıda oynatma listesi yok. “list=” içeren bir bağlantı kullanın.",
    "Mixes, Watch Later and Liked lists can't be listed. Try a regular public playlist.":
        "Karışımlar, Daha Sonra İzle ve Beğenilenler listelenemez. Normal, herkese açık bir oynatma listesi deneyin.",
    "Playlist not found. It may be private or deleted, or the link may be incomplete.":
        "Oynatma listesi bulunamadı. Gizli veya silinmiş olabilir ya da bağlantı eksik olabilir.",
    "This playlist is private. Only public and unlisted playlists can be listed.":
        "Bu oynatma listesi gizli. Yalnızca herkese açık ve liste dışı oynatma listeleri listelenebilir.",
    "The daily lookup limit has been reached. Please try again tomorrow.":
        "Günlük sorgu sınırına ulaşıldı. Lütfen yarın tekrar deneyin.",
    "Too many requests. Please wait a minute and try again.":
        "Çok fazla istek gönderildi. Lütfen bir dakika bekleyip tekrar deneyin.",
    "No internet connection. Check your network and try again.":
        "İnternet bağlantısı yok. Ağınızı kontrol edip tekrar deneyin.",
    "The service is temporarily unavailable. Please try again later.":
        "Hizmet geçici olarak kullanılamıyor. Lütfen daha sonra tekrar deneyin.",
    "Received an unexpected response. Please try again later.":
        "Beklenmeyen bir yanıt alındı. Lütfen daha sonra tekrar deneyin.",
    # Ekran görüntüsü başlıkları (yalnız DEBUG derlemede kullanılır)
    "Every link in a playlist, in one click": "Bir listedeki tüm bağlantılar, tek tıkla",
    "Paste a public playlist link and get a clean list of video links right from your menu bar.":
        "Herkese açık bir oynatma listesi bağlantısını yapıştırın, video bağlantılarının temiz listesini doğrudan menü çubuğunuzdan alın.",
    "Copy or save the whole list": "Listenin tamamını kopyalayın veya kaydedin",
    "Copy all links to the clipboard or save them as a plain text file.":
        "Tüm bağlantıları panoya kopyalayın veya düz metin dosyası olarak kaydedin.",
    "Clear messages when something's wrong": "Bir sorun olduğunda anlaşılır mesajlar",
    "Private, deleted or unsupported playlists are explained in plain words.":
        "Gizli, silinmiş veya desteklenmeyen oynatma listeleri sade bir dille açıklanır.",
}

def unit(v):
    return {"stringUnit": {"state": "translated", "value": v}}

def plural(one, other):
    return {"variations": {"plural": {"one": unit(one), "other": unit(other)}}}

strings = {k: {"localizations": {"tr": unit(v)}} for k, v in TR.items()}

strings["Fetching playlist… %lld videos so far"] = {"localizations": {
    "en": plural("Fetching playlist… %lld video so far", "Fetching playlist… %lld videos so far"),
    "tr": unit("Oynatma listesi alınıyor… şu ana kadar %lld video"),
}}
strings["%lld videos found"] = {"localizations": {
    "en": plural("%lld video found", "%lld videos found"),
    "tr": unit("%lld video bulundu"),
}}
strings["%lld links copied to the clipboard"] = {"localizations": {
    "en": plural("%lld link copied to the clipboard", "%lld links copied to the clipboard"),
    "tr": unit("%lld bağlantı panoya kopyalandı"),
}}

def sub(arg, one, other):
    return {"argNum": arg, "formatSpecifier": "lld",
            "variations": {"plural": {"one": unit(one), "other": unit(other)}}}

strings["%lld videos found, %lld private or deleted skipped"] = {"localizations": {
    "en": {
        "stringUnit": {"state": "translated", "value": "%#@videos@, %#@skipped@"},
        "substitutions": {
            "videos": sub(1, "%arg video found", "%arg videos found"),
            "skipped": sub(2, "%arg private or deleted skipped", "%arg private or deleted skipped"),
        },
    },
    "tr": unit("%1$lld video bulundu, gizli veya silinmiş %2$lld video atlandı"),
}}

catalog = {"sourceLanguage": "en", "strings": dict(sorted(strings.items())), "version": "1.0"}
out = pathlib.Path(__file__).resolve().parent.parent / "Sources/PlaylistURLExtractorKit/Resources/Localizable.xcstrings"
out.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"{len(strings)} anahtar → {out}")
