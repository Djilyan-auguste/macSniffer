import Foundation
import SwiftUI

struct TreemapRect: Identifiable, Equatable {
    var id: String { node.id }
    let node: FileNode
    let x: Double
    let y: Double
    let width: Double
    let height: Double
    var isContainer: Bool = false
    var level: Int = 0
}

enum TreemapError: Error {
    case emptyNode
    case invalidRect
}

private func finite(_ value: Double) -> Double {
    if value.isNaN || value.isInfinite || value < 0 { return 0 }
    return value
}

private func clampedSize(_ value: Double, min: Double = 1) -> Double {
    let v = finite(value)
    return Swift.max(v, min)
}

/// Squarified treemap for a single level: lays out the children of `node`.
/// Small children are grouped into an "Other" bucket so the view is never
/// cluttered with tiny slivers.
func squarifyTreemap(node: FileNode, x: Double, y: Double, width: Double, height: Double, level: Int = 0) -> [TreemapRect] {
    let w = finite(width)
    let h = finite(height)
    let minVisible: Double = 4

    guard node.size > 0, w >= minVisible, h >= minVisible else { return [] }

    let children = node.children
        .filter { $0.size > 0 }
        .sorted { $0.size > $1.size }

    guard !children.isEmpty else {
        return [TreemapRect(node: node, x: x, y: y, width: w, height: h, isContainer: false, level: level)]
    }

    // Group tiny children into an "Other" node so they don't produce invisible slivers.
    let minAreaRatio: Double = 0.005 // at least 0.5% of the parent area
    let totalArea = w * h
    let minArea = totalArea * minAreaRatio

    var displayChildren: [FileNode] = []
    var otherSize: Int64 = 0
    for child in children {
        let area = Double(child.size) / Double(node.size) * totalArea
        if area < minArea && !child.isDirectory {
            otherSize += child.size
        } else {
            displayChildren.append(child)
        }
    }
    if otherSize > 0 {
        let otherURL = node.url.appendingPathComponent(".other")
        displayChildren.append(FileNode.leaf(url: otherURL, size: otherSize, depth: node.depth + 1))
    }

    return layoutRects(children: displayChildren, parentSize: node.size, x: x, y: y, width: w, height: h, level: level)
}

private func layoutRects(children: [FileNode], parentSize: Int64, x: Double, y: Double, width: Double, height: Double, level: Int) -> [TreemapRect] {
    let w = finite(width)
    let h = finite(height)

    guard parentSize > 0, w > 0, h > 0 else { return [] }

    let totalSize = Double(children.reduce(Int64(0)) { $0 + $1.size })
    guard totalSize > 0, totalSize.isFinite else { return [] }
    let scale = (w * h) / totalSize

    var rects: [TreemapRect] = []
    var rx = finite(x), ry = finite(y), rw = w, rh = h
    var row: [(node: FileNode, area: Double)] = []
    var rowArea: Double = 0

    func worst(_ items: [(node: FileNode, area: Double)], _ area: Double, _ side: Double) -> Double {
        guard area > 0, side > 0 else { return .infinity }
        let thickness = area / side
        return items.reduce(1.0) { acc, item in
            let len = item.area / thickness
            return max(acc, max(thickness / len, len / thickness))
        }
    }

    func flushRow() {
        defer { row.removeAll(); rowArea = 0 }
        guard rowArea > 0, rw > 0, rh > 0 else { return }

        let landscape = rw >= rh
        let side = landscape ? rh : rw
        let thickness = min(rowArea / side, landscape ? rw : rh)
        guard thickness > 0 else { return }

        var offset: Double = 0
        for item in row {
            let len = item.area / thickness
            let r = landscape
                ? TreemapRect(node: item.node, x: rx, y: ry + offset, width: thickness, height: len)
                : TreemapRect(node: item.node, x: rx + offset, y: ry, width: len, height: thickness)
            offset += len
            guard r.width >= 4, r.height >= 4 else { continue }
            rects.append(r)
        }

        if landscape {
            rx += thickness
            rw = max(rw - thickness, 0)
        } else {
            ry += thickness
            rh = max(rh - thickness, 0)
        }
    }

    for child in children {
        let area = Double(child.size) * scale
        guard area > 0, area.isFinite else { continue }
        let side = min(rw, rh)

        if row.isEmpty || worst(row + [(child, area)], rowArea + area, side) <= worst(row, rowArea, side) {
            row.append((child, area))
            rowArea += area
        } else {
            flushRow()
            row.append((child, area))
            rowArea += area
        }
    }
    flushRow()

    return rects
}

/// SpaceSniffer-style palette: deterministic, harmonious colours that stay similar
/// in tone but remain distinguishable. Folders are slightly less saturated than files.
func colorForNode(_ node: FileNode, depth: Int, totalSize: Double) -> Color {
    let family = colorFamily(for: node.name)
    let relative = totalSize > 0 ? min(1, Double(node.size) / totalSize) : 0.5
    let brightness = 0.92 - 0.30 * sqrt(relative)
    let saturation = node.isDirectory ? family.saturation * 0.92 : family.saturation
    return Color(hue: family.hue, saturation: saturation, brightness: brightness)
}

private struct ColorFamily {
    let hue: Double
    let saturation: Double
}

private func colorFamily(for name: String) -> ColorFamily {
    switch name.lowercased() {
    case "system":
        return ColorFamily(hue: 0.10, saturation: 0.55) // warm brown / amber
    case "users", "user":
        return ColorFamily(hue: 0.30, saturation: 0.50) // light green / olive
    case "library":
        return ColorFamily(hue: 0.14, saturation: 0.55) // ochre / soft yellow
    case "applications":
        return ColorFamily(hue: 0.60, saturation: 0.50) // soft blue
    case "private", "var", "usr", "opt", "dev":
        return ColorFamily(hue: 0.55, saturation: 0.48) // blue-grey
    case "downloads", "documents", "desktop":
        return ColorFamily(hue: 0.08, saturation: 0.60) // orange / amber
    case "movies", "videos", "music", "pictures", "photos":
        return ColorFamily(hue: 0.18, saturation: 0.55) // golden / tan
    case "developer", "xcode", "projects":
        return ColorFamily(hue: 0.35, saturation: 0.48) // muted green
    case "mail", "messages", "cache", "logs":
        return ColorFamily(hue: 0.50, saturation: 0.45) // slate / dusty blue
    case "games", "steam", "blizzard":
        return ColorFamily(hue: 0.70, saturation: 0.55) // muted purple
    default:
        // Stable fallback palette families mapped by filename hash.
        let palette: [ColorFamily] = [
            ColorFamily(hue: 0.10, saturation: 0.55), // warm brown / amber
            ColorFamily(hue: 0.60, saturation: 0.50), // soft blue
            ColorFamily(hue: 0.30, saturation: 0.50), // light green / olive
            ColorFamily(hue: 0.14, saturation: 0.55), // ochre / soft yellow
        ]
        let hash = abs(name.hashValue)
        return palette[hash % palette.count]
    }
}
