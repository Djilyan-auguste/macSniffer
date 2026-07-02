import Foundation

struct FileNode: Identifiable, Sendable, Equatable {
    var id: String { url.path }
    let url: URL
    let name: String
    let size: Int64
    let isDirectory: Bool
    let children: [FileNode]
    let depth: Int

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

struct ScanResult {
    let root: FileNode
    let totalSize: Int64
    let fileCount: Int
    let folderCount: Int
}

struct ScanProgress: Sendable {
    let scanned: Int
    let currentPath: String
    let totalBytes: Int64
    let rootSnapshot: FileNode?
    let isComplete: Bool
    let error: String?
}

extension FileNode {
    static func leaf(url: URL, size: Int64, depth: Int) -> FileNode {
        FileNode(url: url, name: url.lastPathComponent, size: size, isDirectory: false, children: [], depth: depth)
    }

    static func directory(url: URL, size: Int64, children: [FileNode], depth: Int) -> FileNode {
        FileNode(url: url, name: url.lastPathComponent, size: size, isDirectory: true, children: children, depth: depth)
    }

    /// Returns a new tree with the node at `targetURL` removed, and parent sizes recalculated.
    /// If the target is the root itself, returns `nil`.
    func removingNode(at targetURL: URL) -> FileNode? {
        guard url != targetURL else { return nil }
        let filtered = children.compactMap { $0.removingNode(at: targetURL) }
        let newSize = isDirectory ? filtered.reduce(0) { $0 + $1.size } : size
        return FileNode(
            url: url,
            name: name,
            size: newSize,
            isDirectory: isDirectory,
            children: filtered,
            depth: depth
        )
    }

    /// Returns the node (or root) reachable by the given URL path, or `nil` if not found.
    func node(at targetURL: URL) -> FileNode? {
        if url == targetURL { return self }
        return children.lazy.compactMap { $0.node(at: targetURL) }.first
    }
}
