<div align="center">
  <img src="logo.png" alt="macSniffer logo" width="160" height="160">
  <h1>macSniffer</h1>
  <p><strong>Disk space visualizer for macOS</strong></p>
  <p>See what eats your storage at a glance.</p>

  ![Swift Version](https://img.shields.io/badge/Swift-6.0-orange.svg)
  ![Platform](https://img.shields.io/badge/platform-macOS%2013+-blue.svg)
  ![License](https://img.shields.io/badge/license-MIT-green.svg)
</div>

---

A native macOS disk-space visualizer inspired by [SpaceSniffer](http://www.uderzo.it/main_products/space_sniffer/). It turns your disk usage into a live, interactive treemap so you can instantly see what is eating your storage.

Built with **Swift**, **SwiftUI**, and **AppKit** for the fastest, most native feel on macOS 13+.

---

## Preview

![macSniffer demo](screenshots/demo.gif)

The app scans your disk and renders a live treemap of disk usage.

---

## What it does

1. **Lists your volumes** — boot disk, external drives, mounted DMGs, etc.
2. **Scans recursively** — walks every folder and file asynchronously.
3. **Draws a treemap** — rectangles sized by disk usage; larger blocks = larger files/folders.
4. **Updates live** — the treemap grows in real time as the scan progresses.
5. **Lets you act** — hover to inspect, click to drill down, right-click to reveal in Finder or move to Trash.

---

## Features

- 🚀 **Native SwiftUI** interface with buttery-smooth 60 FPS animations.
- 🎨 **Deterministic colour palette** — system folders keep the same colour across scans, so you learn the map quickly.
- 🟡 **Yellow title bar** with warm beige UI — easy on the eyes.
- 🔒 **Single permission flow** — asks for Full Disk Access once at launch, no repeated system prompts.
- 🧀 **Cheese logo** because it’s a little silly and memorable.
- 🖱️ **Hover & click** to drill into folders.
- ⌫ **Delete** files/folders directly from the treemap.
- 📦 **Self-contained** — no external dependencies.

---

## Download

Download the latest `.dmg` from the [Releases page](https://github.com/Djilyan-auguste/macSniffer/releases/tag/v1.0.0).

1. Open the `.dmg`.
2. Drag **macSniffer** into **Applications**.
3. Launch it. If Gatekeeper warns you, right-click the app and choose **Open** (this build is not signed or notarized).

Or build from source:

```bash
git clone https://github.com/Djilyan-auguste/macSniffer.git
cd macSniffer
swift build
open .build/debug/macSniffer.app
```

---

## Requirements

- macOS 13.0+
- Xcode 15+ (optional — `swift build` works)
- Swift 6.0+

---

## Permissions

macSniffer needs **Full Disk Access** to scan protected system folders (like `~/Library`, `/System`, `/Users`, etc.).

1. Launch macSniffer.
2. Click **Open System Settings** on the permission screen.
3. Go to **Privacy & Security → Full Disk Access**.
4. Add **macSniffer** and toggle it on.
5. Click **Check again** in macSniffer (or relaunch the app).

This is requested **once**. After that, the app will never ask again.

---

## How it works

### Architecture

```text
┌─────────────┐     ┌──────────────┐     ┌──────────────┐
│ ContentView │────▶│ AppViewModel │────▶│ DiskScanner  │
│   (SwiftUI) │     │ (Observable) │     │(FileManager) │
└─────────────┘     └──────────────┘     └──────────────┘
                           │                       │
                           ▼                       ▼
                    ┌──────────────┐      ┌──────────────┐
                    │  TreemapView │      │  AsyncStream │
                    │(Squarified)  │      │  progress    │
                    └──────────────┘      └──────────────┘
```

### Scanning

The scanner uses an **asynchronous `FileManager` walk** with `Task` and `Task.yield` so the UI never freezes, even on drives with hundreds of thousands of files. It streams partial results back to the view model, which re-renders the treemap every ~200 ms.

### Treemap layout

The layout uses a **squarified treemap** algorithm. It sorts children by size, packs them into rows, and tries to keep each rectangle as close to a square as possible. This makes it easy to compare sizes visually.

### Colours

Colours are assigned by **folder name**, not by randomness, so your disk looks the same every time you scan:

| Folder | Colour |
|---|---|
| `System` | warm brown / amber |
| `Users` | light green / olive |
| `Library` | ochre / soft yellow |
| `Applications` | soft blue |
| `private`, `var`, `usr`, `opt`, `dev` | blue-grey |
| `Downloads`, `Documents`, `Desktop` | orange / amber |
| `Movies`, `Music`, `Pictures`, `Photos` | golden / tan |
| `Developer`, `Xcode`, `Projects` | muted green |
| `Mail`, `Messages`, `Cache`, `Logs` | slate / dusty blue |
| `Games`, `Steam`, `Blizzard` | muted purple |

---

## Screenshots

| Splash | Home | Scanning | Treemap |
|---|---|---|---|
| ![Splash](screenshots/splash.png) | ![Home](screenshots/home.png) | ![Scanning](screenshots/scanning.png) | ![Treemap](screenshots/treemap.png) |

*(Replace these placeholders with real screenshots in the `screenshots/` folder.)*

---

## Roadmap

- [ ] Signed & notarized release.
- [ ] Scan history and recent targets.
- [ ] Export scan results to JSON/CSV.
- [ ] Search/filter by name or size.
- [ ] Dark mode support.
- [ ] Spotlight-style quick scan of a folder from Finder.
- [ ] Animated scan progress ring.
- [ ] Compare two scans over time.

---

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

## Credits

- Inspired by [SpaceSniffer](http://www.uderzo.it/main_products/space_sniffer/) by UderzoSoftware.
- Cheese logo by the macSniffer community. 🧀
