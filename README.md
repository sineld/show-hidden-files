<div align="center">
  <img src="Resources/AppIcon-1024.png" alt="Show Hidden Files icon" width="128" height="128" />
  <h1>Show Hidden Files</h1>
  <p><strong>A lightweight, open-source tool to show and hide files and folders on macOS</strong></p>
  <p>
    <a href="https://github.com/sineld/show-hidden-files/releases/latest"><img src="https://img.shields.io/github/v/release/sineld/show-hidden-files" alt="Latest release" /></a>
    <img src="https://img.shields.io/badge/macOS-13%2B-lightgrey.svg" alt="macOS 13+" />
    <img src="https://img.shields.io/badge/Universal-Apple%20Silicon%20%2B%20Intel-black.svg" alt="Universal" />
    <img src="https://img.shields.io/badge/notarized-Apple-blue.svg" alt="Notarized" />
    <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-brightgreen.svg" alt="MIT License" /></a>
  </p>
  <img src="docs/screenshot.png" alt="Show Hidden Files screenshot" width="420" />
  <p><a href="#türkçe">Türkçe</a></p>
</div>

---

## Why?

This app is inspired by the classic **Show Hidden Files** utility published by [GoToes.org](https://gotoes.org/sales/ShowHiddenFilesMacOSX/). The original was built for Intel Macs only and is no longer developed. This version keeps the same interface and workflow, but it is **rewritten from scratch in Swift** and ships as a **Universal** app (Apple Silicon + Intel), so it needs no Rosetta.

> No code from the original app was used. This is an independent rewrite and is not affiliated with GoToes.org.

## Features

| | |
|---|---|
| **Show / hide special files** | Toggles Finder's `AppleShowAllFiles` setting and restarts Finder, so every hidden item, including files that start with `.`, becomes visible. |
| **Drag & drop** | Drop files and folders from Finder onto the list or onto the Dock icon. |
| **File / folder picker** | Add items with a picker that also shows hidden items. You can also type or paste paths. |
| **Make invisible / visible** | Hide the listed items in Finder, or make them visible again, in one click. Items hidden with the legacy `SetFile -a V` become visible too. |

## Download

Get `ShowHiddenFiles-<version>-universal.zip` from the [latest release](https://github.com/sineld/show-hidden-files/releases/latest), unzip it and move **Show Hidden Files.app** to your Applications folder. The app is signed with a Developer ID and notarized by Apple, so it opens without Gatekeeper warnings.

## Build from source

Requirements: macOS 13 Ventura or later and Xcode (for the Universal build).

```bash
git clone https://github.com/sineld/show-hidden-files.git
cd show-hidden-files
./build-app.sh                # → build/Show Hidden Files.app (ad-hoc signed)
```

Use `swift run` during development.

To make a signed and notarized release archive, use an App Store Connect API key:

```bash
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
NOTARY_KEY_ID=XXXXXXXXXX NOTARY_ISSUER=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
./release.sh                  # → build/ShowHiddenFiles-<version>-universal.zip
```

## How it works

There are no external dependencies and no legacy Carbon tools (`SetFile`). The app calls macOS directly:

- **Hide / show:** changes the file's BSD `UF_HIDDEN` flag (same as `chflags -h hidden`). For a symbolic link, the link itself changes, never its target. The file's other flags are kept.
- **Legacy compatibility:** also updates the `kIsInvisible` bit in `com.apple.FinderInfo`.
- **Special files:** runs `defaults write com.apple.finder AppleShowAllFiles`, then `killall Finder`.

To show hidden files temporarily in Finder, you can also press <kbd>⌘</kbd> <kbd>⇧</kbd> <kbd>.</kbd>.

## Project structure

```text
Sources/ShowHiddenFiles/
├── ShowHiddenFilesApp.swift      # App entry point and About panel
├── ContentView.swift             # Main window and state
├── DropTextView.swift            # Drag-and-drop list area
└── FileVisibilityService.swift   # Visibility and Finder operations
Resources/                        # Info.plist, icon and the script that draws it
build-app.sh                      # Builds and signs the Universal .app
release.sh                        # Signs, notarizes and zips a release
```

## Contributing

Bug reports and pull requests are welcome. Please start by opening an [issue](https://github.com/sineld/show-hidden-files/issues).

## License

[MIT](LICENSE) © 2026 [Sinan Eldem](https://sinaneldem.tr) · [sinan@sinaneldem.tr](mailto:sinan@sinaneldem.tr)

---

<a id="türkçe"></a>

## Türkçe

**Show Hidden Files**, macOS'ta dosya ve klasörleri gizlemek ya da görünür yapmak için hafif ve açık kaynak bir araçtır.

### Neden?

Bu uygulama, [GoToes.org](https://gotoes.org/sales/ShowHiddenFilesMacOSX/) tarafından yayımlanan klasik **Show Hidden Files** aracından esinlenerek yazıldı. Orijinal uygulama yalnızca Intel işlemciler için derlenmişti ve artık geliştirilmiyor. Bu sürüm aynı arayüzü ve iş akışını koruyarak **Swift ile sıfırdan** yazıldı ve **Universal** (Apple Silicon + Intel) olarak derleniyor. Rosetta gerekmez.

> Orijinal uygulamanın kaynak kodu kullanılmamıştır. Bu proje bağımsız bir yeniden yazımdır ve GoToes.org ile bir bağlantısı yoktur.

### Özellikler

- **Özel dosyaları göster / gizle:** Finder'ın `AppleShowAllFiles` ayarını açıp kapatır ve Finder'ı yeniden başlatır. `.` ile başlayan dosyalar dahil bütün gizli öğeler görünür olur.
- **Sürükle ve bırak:** Finder'dan dosya ve klasörleri listeye ya da Dock'taki simgeye bırakın.
- **Dosya / klasör seçici:** Gizli öğeleri de gösteren seçici penceresiyle listeye ekleme yapın. Yolları elle de yazabilir veya yapıştırabilirsiniz.
- **Görünmez / görünür yap:** Listedeki öğeleri tek tıkla Finder'da gizleyin ya da yeniden görünür yapın. Eski `SetFile -a V` ile gizlenmiş öğeler de görünür hâle gelir.

### İndirme

[Son sürüm](https://github.com/sineld/show-hidden-files/releases/latest) sayfasından `ShowHiddenFiles-<sürüm>-universal.zip` dosyasını indirin, açın ve **Show Hidden Files.app** uygulamasını Uygulamalar klasörüne taşıyın. Uygulama Developer ID ile imzalı ve Apple tarafından onaylı (notarized) olduğu için Gatekeeper uyarısı olmadan açılır.

### Kaynaktan derleme

Gereksinimler: macOS 13 Ventura veya üzeri, Xcode (Universal derleme için).

```bash
git clone https://github.com/sineld/show-hidden-files.git
cd show-hidden-files
./build-app.sh                # → build/Show Hidden Files.app (yerel imzalı)
```

Geliştirme sırasında `swift run` yeterlidir. İmzalı ve onaylı bir yayın paketi için yukarıdaki İngilizce bölümdeki `release.sh` komutunu kullanın.

### Nasıl çalışır?

Harici bağımlılık ya da eski Carbon araçları (`SetFile`) kullanılmaz; doğrudan macOS sistem çağrıları kullanılır:

- **Gizleme / gösterme:** Dosyanın BSD `UF_HIDDEN` bayrağı değiştirilir (`chflags -h hidden` ile aynı). Sembolik linklerde linkin gösterdiği dosyaya değil, linkin kendisine dokunulur. Dosyanın diğer bayrakları korunur.
- **Eski uyumluluk:** `com.apple.FinderInfo` içindeki `kIsInvisible` biti de güncellenir.
- **Özel dosyalar:** `defaults write com.apple.finder AppleShowAllFiles` ve ardından `killall Finder`.

Gizli dosyaları Finder'da geçici olarak göstermek için <kbd>⌘</kbd> <kbd>⇧</kbd> <kbd>.</kbd> kısayolunu da kullanabilirsiniz.

### Katkı ve lisans

Hata bildirimleri ve pull request'ler memnuniyetle karşılanır; lütfen bir [issue](https://github.com/sineld/show-hidden-files/issues) açarak başlayın. Proje [MIT lisansı](LICENSE) ile dağıtılır.
