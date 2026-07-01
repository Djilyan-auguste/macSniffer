import Foundation

final class DiskScanner: @unchecked Sendable {
    private var stopRequested = false

    func stop() {
        stopRequested = true
    }

    func scan(
        url: URL,
        progressHandler: @escaping @Sendable (ScanProgress) -> Void
    ) async -> ScanResult? {
        stopRequested = false
        let resourceKeys: [URLResourceKey] = [.isRegularFileKey, .isDirectoryKey, .fileSizeKey, .fileAllocatedSizeKey]

        var totalSize: Int64 = 0
        var fileCount = 0
        var folderCount = 0
        var scanned = 0

        func buildNode(for url: URL, depth: Int) -> FileNode? {
            guard !stopRequested else { return nil }

            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else { return nil }

            if isDirectory.boolValue {
                folderCount += 1
                var children: [FileNode] = []
                do {
                    let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: resourceKeys)
                    for child in contents {
                        if let node = buildNode(for: child, depth: depth + 1) {
                            children.append(node)
                        }
                    }
                } catch {
                    // Permission denied or unreadable directory.
                }
                let dirSize = children.reduce(0) { $0 + $1.size }
                return FileNode.directory(url: url, size: dirSize, children: children, depth: depth)
            } else {
                fileCount += 1
                var fileSize: Int64 = 0
                do {
                    let values = try url.resourceValues(forKeys: Set(resourceKeys))
                    fileSize = Int64(values.fileSize ?? 0)
                    if let allocated = values.fileAllocatedSize {
                        fileSize = max(fileSize, Int64(allocated))
                    }
                    totalSize += fileSize
                } catch {
                    fileSize = 0
                }
                scanned += 1
                progressHandler(ScanProgress(scanned: scanned, currentPath: url.path, totalBytes: totalSize))
                return FileNode.leaf(url: url, size: fileSize, depth: depth)
            }
        }

        guard let rootNode = buildNode(for: url, depth: 0) else { return nil }
        return ScanResult(root: rootNode, totalSize: totalSize, fileCount: fileCount, folderCount: folderCount)
    }
}
