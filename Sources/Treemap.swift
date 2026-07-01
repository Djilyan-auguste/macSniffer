import Foundation

struct TreemapRect: Identifiable {
    let id = UUID()
    let node: FileNode
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}

enum TreemapError: Error {
    case emptyNode
    case invalidRect
}

/// Squarified treemap algorithm. Divides a rectangle proportionally by size.
func squarifyTreemap(node: FileNode, x: Double, y: Double, width: Double, height: Double) -> [TreemapRect] {
    guard node.size > 0 else { return [] }
    guard !node.children.isEmpty else {
        return [TreemapRect(node: node, x: x, y: y, width: width, height: height)]
    }

    let total = Double(node.children.reduce(0) { $0 + $1.size })
    guard total > 0 else { return [] }

    var rects: [TreemapRect] = []
    let sorted = node.children.sorted { $0.size > $1.size }

    var remaining = TreemapRect(node: node, x: x, y: y, width: width, height: height)

    var row: [FileNode] = []
    var rowSize: Double = 0

    func flushRow() {
        guard !row.isEmpty else { return }

        let rowTotal = rowSize
        let isHorizontal = remaining.width >= remaining.height
        let rowLength = isHorizontal ? remaining.width : remaining.height
        let rowThickness = rowTotal / total * (isHorizontal ? remaining.height : remaining.width)

        var currentOffset: Double = 0
        for item in row {
            let itemRatio = Double(item.size) / rowTotal
            let itemMain = itemRatio * rowLength
            let itemRect: TreemapRect
            if isHorizontal {
                itemRect = TreemapRect(node: item, x: remaining.x + currentOffset, y: remaining.y, width: itemMain, height: rowThickness)
                currentOffset += itemMain
            } else {
                itemRect = TreemapRect(node: item, x: remaining.x, y: remaining.y + currentOffset, width: rowThickness, height: itemMain)
                currentOffset += itemMain
            }

            rects.append(itemRect)

            // Recurse into directories
            if item.isDirectory, !item.children.isEmpty {
                let childRects = squarifyTreemap(node: item, x: itemRect.x, y: itemRect.y, width: itemRect.width, height: itemRect.height)
                rects.append(contentsOf: childRects)
            }
        }

        if isHorizontal {
            remaining = TreemapRect(node: node, x: remaining.x, y: remaining.y + rowThickness, width: remaining.width, height: remaining.height - rowThickness)
        } else {
            remaining = TreemapRect(node: node, x: remaining.x + rowThickness, y: remaining.y, width: remaining.width - rowThickness, height: remaining.height)
        }

        row.removeAll()
        rowSize = 0
    }

    func worstAspectRatio(_ items: [FileNode], _ size: Double, _ side: Double) -> Double {
        let total = items.reduce(0) { $0 + Double($1.size) }
        guard total > 0 else { return .infinity }
        let w2 = total * total
        let side2 = side * side
        let minArea = Double(items.map { $0.size }.min() ?? 0)
        let maxArea = Double(items.map { $0.size }.max() ?? 0)
        guard minArea > 0 else { return .infinity }
        return max(side2 * maxArea / w2, w2 / (side2 * minArea))
    }

    for child in sorted {
        let childSize = Double(child.size)
        let side = min(remaining.width, remaining.height)
        let currentRatio = row.isEmpty ? .infinity : worstAspectRatio(row, rowSize, side)
        let newRatio = worstAspectRatio(row + [child], rowSize + childSize, side)

        if row.isEmpty || newRatio <= currentRatio {
            row.append(child)
            rowSize += childSize
        } else {
            flushRow()
            row.append(child)
            rowSize += childSize
        }
    }
    flushRow()

    return rects
}

func colorForNode(_ node: FileNode, depth: Int) -> String {
    let hue = (Double(depth) * 47.0 + 200).truncatingRemainder(dividingBy: 360)
    return "hsl(\(Int(hue)), 70%, 55%)"
}
