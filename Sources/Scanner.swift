import Foundation

struct Volume: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let name: String
    var size: Int64
    var freeSpace: Int64

    var usedSpace: Int64 { size - freeSpace }

    var formattedSize: String { ByteCountFormatter().string(fromByteCount: size) }
    var formattedFreeSpace: String { ByteCountFormatter().string(fromByteCount: freeSpace) }
    var formattedUsedSpace: String { ByteCountFormatter().string(fromByteCount: usedSpace) }

    mutating func refreshFreeSpace() {
        let keys: Set<URLResourceKey> = [.volumeTotalCapacityKey, .volumeAvailableCapacityKey]
        guard let values = try? url.resourceValues(forKeys: keys) else { return }
        if let total = values.volumeTotalCapacity { size = Int64(total) }
        if let free = values.volumeAvailableCapacity { freeSpace = Int64(free) }
    }
}

func listVolumes() -> [Volume] {
    let keys: [URLResourceKey] = [.volumeNameKey, .volumeTotalCapacityKey, .volumeAvailableCapacityKey]
    guard let urls = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: .skipHiddenVolumes) else { return [] }

    return urls.compactMap { url in
        guard let values = try? url.resourceValues(forKeys: Set(keys)) else { return nil }
        let name = values.volumeName ?? url.path
        let total = values.volumeTotalCapacity ?? 0
        let free = values.volumeAvailableCapacity ?? 0
        return Volume(url: url, name: name, size: Int64(total), freeSpace: Int64(free))
    }
}

actor DiskScanner {
    private var stopRequested = false

    func stop() {
        stopRequested = true
    }

    func scan(url: URL) -> AsyncStream<ScanProgress> {
        stopRequested = false
        let (stream, continuation) = AsyncStream<ScanProgress>.makeStream()

        Task {
            await runScan(url: url, continuation: continuation)
        }

        return stream
    }

    private func runScan(url: URL, continuation: AsyncStream<ScanProgress>.Continuation) async {
        do {
            try await scanRoot(url: url, continuation: continuation)
        } catch {
            let message = "Scan error: \(error.localizedDescription). If scanning a protected disk, grant Full Disk Access in System Settings > Privacy & Security."
            continuation.yield(ScanProgress(scanned: 0, currentPath: url.path, totalBytes: 0, rootSnapshot: nil, isComplete: true, error: message))
            continuation.finish()
        }
    }

    private func scanRoot(url: URL, continuation: AsyncStream<ScanProgress>.Continuation) async throws {
        let startTime = Date()

        // Phase 1: list top-level items, with timeout protection per item.
        let contents = (try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)) ?? []

        let topChildren: [FileNode] = await withTaskGroup(of: FileNode?.self) { group in
            for child in contents {
                group.addTask {
                    await self.quickSizeNode(for: child, depth: 1, continuation: continuation)
                }
            }
            var nodes: [FileNode] = []
            for await node in group {
                if let node = node { nodes.append(node) }
            }
            return nodes
        }

        let sortedChildren = topChildren.sorted { $0.size > $1.size }
        let quickRoot = FileNode.directory(url: url, size: sortedChildren.reduce(0) { $0 + $1.size }, children: sortedChildren, depth: 0)

        continuation.yield(ScanProgress(
            scanned: sortedChildren.count,
            currentPath: url.path,
            totalBytes: quickRoot.size,
            rootSnapshot: quickRoot,
            isComplete: false,
            error: nil
        ))

        guard !stopRequested else {
            continuation.yield(ScanProgress(scanned: sortedChildren.count, currentPath: url.path, totalBytes: quickRoot.size, rootSnapshot: quickRoot, isComplete: true, error: nil))
            continuation.finish()
            return
        }

        // Phase 2: deep scan top directories, one by one to avoid overwhelming the system.
        let topDirectories = sortedChildren.filter { $0.isDirectory }.prefix(10)
        var refined: [(Int, FileNode)] = []

        for (index, child) in topDirectories.enumerated() {
            if stopRequested { break }
            let deep = await deepScanNode(for: child.url, depth: child.depth, continuation: continuation)
            refined.append((index, deep))
        }

        // Merge refined children back into the tree.
        let refinedSorted = refined.sorted { $0.0 < $1.0 }.map { $0.1 }
        var finalChildren: [FileNode] = []
        var refinedIndex = 0
        for child in sortedChildren {
            if child.isDirectory, refinedIndex < refinedSorted.count, child.url == refinedSorted[refinedIndex].url {
                finalChildren.append(refinedSorted[refinedIndex])
                refinedIndex += 1
            } else {
                finalChildren.append(child)
            }
        }

        let finalRoot = FileNode.directory(url: url, size: finalChildren.reduce(0) { $0 + $1.size }, children: finalChildren, depth: 0)

        continuation.yield(ScanProgress(
            scanned: sortedChildren.count + refined.reduce(0) { $0 + countNodes($1.1) },
            currentPath: url.path,
            totalBytes: finalRoot.size,
            rootSnapshot: finalRoot,
            isComplete: true,
            error: nil
        ))
        continuation.finish()

        let elapsed = Date().timeIntervalSince(startTime)
        print("Scan completed in \(String(format: "%.2f", elapsed))s")
    }

    private func quickSizeNode(for url: URL, depth: Int, continuation: AsyncStream<ScanProgress>.Continuation) async -> FileNode? {
        guard !stopRequested else { return nil }

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else { return nil }

        if isDirectory.boolValue {
            let (size, children) = await fastDirectorySize(url: url, depth: depth, continuation: continuation)
            return FileNode.directory(url: url, size: size, children: children, depth: depth)
        } else {
            return FileNode.leaf(url: url, size: fileSize(at: url), depth: depth)
        }
    }

    /// Compute directory size by walking contents recursively but shallowly for the quick pass.
    private func fastDirectorySize(url: URL, depth: Int, continuation: AsyncStream<ScanProgress>.Continuation) async -> (Int64, [FileNode]) {
        guard !stopRequested else { return (0, []) }
        var total: Int64 = 0
        var children: [FileNode] = []
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            for child in contents {
                if stopRequested { break }
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: child.path, isDirectory: &isDir), isDir.boolValue {
                    let childSize = directorySizeFastSync(at: child, maxDepth: 3, currentDepth: 0)
                    total += childSize
                    children.append(FileNode.directory(url: child, size: childSize, children: [], depth: depth + 1))
                } else {
                    let size = fileSize(at: child)
                    total += size
                    children.append(FileNode.leaf(url: child, size: size, depth: depth + 1))
                }
            }
        } catch { }
        children.sort { $0.size > $1.size }
        return (total, children)
    }

    private func directorySizeFastSync(at url: URL, maxDepth: Int, currentDepth: Int) -> Int64 {
        guard currentDepth <= maxDepth else { return 0 }
        var total: Int64 = 0
        guard let contents = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) else { return 0 }
        for child in contents {
            if stopRequested { break }
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: child.path, isDirectory: &isDir), isDir.boolValue {
                total += directorySizeFastSync(at: child, maxDepth: maxDepth, currentDepth: currentDepth + 1)
            } else {
                total += fileSize(at: child)
            }
        }
        return total
    }

    private func deepScanNode(for url: URL, depth: Int, continuation: AsyncStream<ScanProgress>.Continuation) async -> FileNode {
        guard !stopRequested else {
            return FileNode.directory(url: url, size: 0, children: [], depth: depth)
        }

        var children: [FileNode] = []
        var fileCount = 0
        guard let contents = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) else {
            return FileNode.directory(url: url, size: 0, children: [], depth: depth)
        }

        for child in contents {
            if stopRequested { break }
            if isDirectory(at: child) {
                // Limit depth to avoid scanning endless system trees.
                guard depth < 5 else {
                    children.append(FileNode.directory(url: child, size: directorySizeFastSync(at: child, maxDepth: 0, currentDepth: 0), children: [], depth: depth + 1))
                    continue
                }
                let deep = await deepScanNode(for: child, depth: depth + 1, continuation: continuation)
                children.append(deep)
            } else {
                let size = fileSize(at: child)
                children.append(FileNode.leaf(url: child, size: size, depth: depth + 1))
                fileCount += 1
            }

            if fileCount % 512 == 0 {
                await Task.yield()
            }
        }

        children.sort { $0.size > $1.size }
        let dirSize = children.reduce(0) { $0 + $1.size }
        return FileNode.directory(url: url, size: dirSize, children: children, depth: depth)
    }

    private func isDirectory(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    private func fileSize(at url: URL) -> Int64 {
        do {
            let values = try url.resourceValues(forKeys: [.fileSizeKey, .fileAllocatedSizeKey])
            let logical = Int64(values.fileSize ?? 0)
            let allocated = Int64(values.fileAllocatedSize ?? 0)
            return allocated > 0 ? allocated : logical
        } catch {
            return 0
        }
    }
}

private func countNodes(_ node: FileNode) -> Int {
    1 + node.children.reduce(0) { $0 + countNodes($1) }
}
