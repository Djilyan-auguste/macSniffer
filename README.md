# macSniffer

A macOS disk usage visualizer inspired by [SpaceSniffer](http://www.uderzo.it/main_products/space_sniffer/), built with **SwiftUI**.

![Swift Version](https://img.shields.io/badge/Swift-6.0-orange.svg)
![Platform](https://img.shields.io/badge/platform-macOS%2013+-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## Features

- 🗂️ Select any folder or disk and scan it recursively.
- 📊 Visualize disk usage as an interactive **squarified treemap**.
- 🖱️ Hover to see file/folder name and size.
- 🎨 Color-coded blocks by directory depth.
- ⚡ Asynchronous scanning — UI stays responsive.

## Requirements

- macOS 13+
- Xcode 15+ or Swift 6.0+

## Run

### With Xcode

1. Open the folder in Xcode.
2. Select **Product → Run**.

### With Swift Package Manager

```bash
swift build
.open .build/debug/macSniffer.app
```

## How it works

1. **Scanner** recursively walks the selected folder using `FileManager`.
2. **Squarified treemap** algorithm divides the viewport into rectangles proportional to file sizes.
3. **SwiftUI** renders the treemap with hover/tap interaction.

## Project structure

```
Sources/
├── App.swift           # App entry point
├── ContentView.swift   # Main UI and view model
├── Models.swift        # FileNode, ScanResult, ScanProgress
├── Scanner.swift       # DiskScanner actor
└── Treemap.swift       # Squarified treemap algorithm + colors
```

## Inspired by

- [SpaceSniffer](http://www.uderzo.it/main_products/space_sniffer/) by Uderzo Software

## License

MIT
