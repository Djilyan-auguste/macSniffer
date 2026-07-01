import Foundation

struct FileNode: Identifiable {
    let id = UUID()
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

struct ScanProgress {
    let scanned: Int
    let currentPath: String
    let totalBytes: Int64
}

extension FileNode {
    static func leaf(url: URL, size: Int64, depth: Int) -> FileNode {
        FileNode(url: url, name: url.lastPathComponent, size: size, isDirectory: false, children: [], depth: depth)
    }

    static func directory(url: URL, size: Int64, children: [FileNode], depth: Int) -> FileNode {
        FileNode(url: url, name: url.lastPathComponent, size: size, isDirectory: true, children: children, depth: depth)
    }
}
