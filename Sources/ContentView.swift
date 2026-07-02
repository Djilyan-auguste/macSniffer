import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()
    @State private var showSplash = true
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            gridBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar

                ZStack {
                    if viewModel.authorizationStatus == .unknown || viewModel.authorizationStatus == .denied {
                        authorizationView
                    } else if let root = viewModel.liveRoot ?? viewModel.result?.root {
                        TreemapView(
                            root: root,
                            selectedNode: $viewModel.selectedNode,
                            navigationStack: $viewModel.navigationStack,
                            isScanning: viewModel.isScanning,
                            onDelete: viewModel.moveToTrash(node:)
                        )
                    } else if viewModel.errorMessage != nil {
                        errorView
                    } else {
                        volumeSelectionView
                    }

                    if viewModel.isScanning {
                        scanningOverlay
                    }

                    if let error = viewModel.errorMessage {
                        errorBanner(error)
                    }
                }

                if let selected = viewModel.selectedNode {
                    selectedNodeBar(selected)
                }
            }
        }
        .preferredColorScheme(.light)
        .frame(minWidth: 900, minHeight: 700)
        .overlay(splashScreen)
    }

    private var authorizationView: some View {
        VStack(spacing: 24) {
            Spacer()

            LogoView(size: 120)

            VStack(spacing: 8) {
                Text("macSniffer")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.35, green: 0.25, blue: 0.18))

                Text("Disk space visualizer")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(red: 0.55, green: 0.45, blue: 0.35))
            }

            VStack(spacing: 10) {
                Text("Full Disk Access required")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(red: 0.35, green: 0.25, blue: 0.18))

                Text("macSniffer needs access to your disk to scan folders and show what is taking up space. This is requested once and never shared.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(red: 0.55, green: 0.45, blue: 0.35))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
                    .lineSpacing(4)
            }

            VStack(spacing: 12) {
                Button {
                    PermissionManager.openFullDiskAccessSettings()
                } label: {
                    Text("Open System Settings")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .tint(Color(red: 0.95, green: 0.70, blue: 0.18))

                Button {
                    viewModel.checkAuthorization()
                } label: {
                    Text("Check again")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.borderless)
                .tint(Color(red: 0.55, green: 0.45, blue: 0.35))

                if viewModel.authorizationStatus == .denied {
                    Text("After enabling access, relaunch macSniffer or tap Check again.")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(red: 0.55, green: 0.45, blue: 0.35))
                        .padding(.top, 8)
                }
            }

            Spacer()
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.98, green: 0.95, blue: 0.90))
    }

    private var gridBackground: some View {
        GeometryReader { geo in
            let step: CGFloat = 40
            Path { path in
                for x in stride(from: 0, to: geo.size.width, by: step) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geo.size.height))
                }
                for y in stride(from: 0, to: geo.size.height, by: step) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                }
            }
            .stroke(Color(red: 0.55, green: 0.45, blue: 0.35).opacity(0.08), lineWidth: 1)
        }
    }

    private var splashScreen: some View {
        ZStack {
            if showSplash {
                Color(red: 0.98, green: 0.95, blue: 0.90)
                    .ignoresSafeArea()
                    .transition(.opacity)

                VStack(spacing: 20) {
                    LogoView(size: 140)
                    VStack(spacing: 4) {
                        Text("macSniffer")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.35, green: 0.25, blue: 0.18))
                        Text("Disk space visualizer")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(red: 0.55, green: 0.45, blue: 0.35))
                    }
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                        .padding(.top, 20)
                        .tint(Color(red: 0.55, green: 0.45, blue: 0.35))
                }
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showSplash)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { showSplash = false }
            }
        }
    }

    private var headerBar: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.resetToVolumeSelection()
            } label: {
                Image(systemName: "house")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(red: 0.35, green: 0.25, blue: 0.18))
            }
            .buttonStyle(.borderless)
            .disabled(viewModel.isScanning)

            if !viewModel.navigationStack.isEmpty {
                Button {
                    viewModel.navigateBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(red: 0.35, green: 0.25, blue: 0.18))
                }
                .buttonStyle(.borderless)

                Button {
                    viewModel.navigateToRoot()
                } label: {
                    Image(systemName: "arrow.up.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(red: 0.35, green: 0.25, blue: 0.18))
                }
                .buttonStyle(.borderless)
            }

            if let _ = viewModel.result, let volume = viewModel.selectedVolume {
                VStack(alignment: .leading, spacing: 1) {
                    Text(volume.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(red: 0.35, green: 0.25, blue: 0.18))
                    Text("\(volume.formattedUsedSpace) used / \(volume.formattedSize) total • \(volume.formattedFreeSpace) free")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(red: 0.55, green: 0.45, blue: 0.35))
                }
            } else if viewModel.isScanning {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Scanning \(viewModel.selectedVolume?.name ?? "disk")")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(red: 0.35, green: 0.25, blue: 0.18))
                    Text("\(viewModel.scannedItems) items scanned")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(red: 0.55, green: 0.45, blue: 0.35))
                }
            } else {
                Text("macSniffer")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(red: 0.35, green: 0.25, blue: 0.18))
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(red: 0.98, green: 0.95, blue: 0.90))
        .overlay(Rectangle().stroke(Color(red: 0.55, green: 0.45, blue: 0.35).opacity(0.12), lineWidth: 1))
    }

    private var scanningOverlay: some View {
        ZStack {
            Color(red: 0.98, green: 0.95, blue: 0.90)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()
                LoadingCubeView()
                    .frame(width: 160, height: 160)
                VStack(spacing: 6) {
                    Text(viewModel.selectedVolume?.name ?? "Scanning")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(red: 0.35, green: 0.25, blue: 0.18))
                    Text("Press Escape to cancel")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(red: 0.55, green: 0.45, blue: 0.35))
                }
                Spacer()
            }
        }
    }

    private var volumeSelectionView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 18) {
                LogoView(size: 120)

                VStack(spacing: 4) {
                    Text("macSniffer")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.35, green: 0.25, blue: 0.18))

                    Text("Disk space visualizer")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(red: 0.55, green: 0.45, blue: 0.35))
                }

                Text("Select a disk to scan every folder and file.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(red: 0.55, green: 0.45, blue: 0.35))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
                    .lineSpacing(4)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 12) {
                Text("Disks")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(red: 0.55, green: 0.45, blue: 0.35))
                    .padding(.horizontal, 4)

                ForEach(viewModel.volumes) { volume in
                    VolumeRow(volume: volume) {
                        viewModel.scan(volume: volume)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.65))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(red: 0.55, green: 0.45, blue: 0.35).opacity(0.12), lineWidth: 1)
            )

            Spacer()

            Button {
                if let url = URL(string: "https://www.buymeacoffee.com/macSniffer") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "cup.and.saucer.fill")
                    Text("Buy me a coffee")
                }
                .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(Color(red: 0.55, green: 0.45, blue: 0.35))
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.98, green: 0.95, blue: 0.90))
        .onAppear { viewModel.refreshVolumes() }
    }

    private var errorView: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.red)
            Text(viewModel.errorMessage ?? "Unknown error")
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(red: 0.35, green: 0.25, blue: 0.18))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.98, green: 0.95, blue: 0.90))
    }

    private func errorBanner(_ error: String) -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Text(error)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(red: 0.35, green: 0.25, blue: 0.18))
                    .padding(10)
                    .background(Color(red: 0.95, green: 0.60, blue: 0.15).opacity(0.85))
                    .cornerRadius(8)
                    .padding(16)
                Spacer()
            }
        }
    }

    private func selectedNodeBar(_ selected: FileNode) -> some View {
        HStack {
            Text(selected.name)
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            Text(selected.formattedSize)
                .font(.system(size: 13, weight: .medium))
                .monospacedDigit()
        }
        .foregroundStyle(Color(red: 0.35, green: 0.25, blue: 0.18))
        .padding(8)
        .background(Color(red: 0.98, green: 0.95, blue: 0.90).opacity(0.92))
        .overlay(Rectangle().stroke(Color(red: 0.55, green: 0.45, blue: 0.35).opacity(0.12), lineWidth: 1))
    }
}

@MainActor
final class AppViewModel: ObservableObject {
    @Published var result: ScanResult?
    @Published var liveRoot: FileNode?
    @Published var isScanning = false
    @Published var scannedItems = 0
    @Published var currentPath = ""
    @Published var errorMessage: String?
    @Published var selectedNode: FileNode?
    @Published var volumes: [Volume] = []
    @Published var selectedVolume: Volume?
    @Published var navigationStack: [FileNode] = []
    @Published var authorizationStatus: AuthorizationStatus = .unknown

    private var scanner: DiskScanner?
    private var task: Task<Void, Never>?

    var currentRoot: FileNode? { navigationStack.last ?? liveRoot ?? result?.root }

    init() {
        checkAuthorization()
    }

    func checkAuthorization() {
        authorizationStatus = PermissionManager.checkFullDiskAccess()
    }

    func refreshVolumes() {
        volumes = listVolumes()
    }

    func resetToVolumeSelection() {
        task?.cancel()
        Task {
            await scanner?.stop()
        }
        result = nil
        liveRoot = nil
        selectedVolume = nil
        selectedNode = nil
        errorMessage = nil
        isScanning = false
        scannedItems = 0
        currentPath = ""
        navigationStack.removeAll()
        refreshVolumes()
    }

    func scan(volume: Volume) {
        selectedVolume = volume
        startScan(url: volume.url)
    }

    private func startScan(url: URL) {
        task?.cancel()
        result = nil
        liveRoot = nil
        errorMessage = nil
        selectedNode = nil
        navigationStack.removeAll()
        isScanning = true
        scannedItems = 0

        let newScanner = DiskScanner()
        scanner = newScanner

        task = Task { [weak self] in
            let stream = await newScanner.scan(url: url)
            var lastUpdate = Date.distantPast
            for await progress in stream {
                let shouldUpdate: Bool = {
                    if progress.isComplete { return true }
                    return Date().timeIntervalSince(lastUpdate) >= 0.2
                }()
                await MainActor.run {
                    self?.scannedItems = progress.scanned
                    self?.currentPath = (progress.currentPath as NSString).lastPathComponent
                    if let snapshot = progress.rootSnapshot, shouldUpdate {
                        self?.liveRoot = snapshot
                    }
                    if let error = progress.error {
                        self?.errorMessage = error
                    }
                }
                if shouldUpdate {
                    lastUpdate = Date()
                }
            }

            await MainActor.run {
                self?.isScanning = false
                if let root = self?.liveRoot, self?.errorMessage == nil {
                    self?.result = ScanResult(
                        root: root,
                        totalSize: root.size,
                        fileCount: 0,
                        folderCount: 0
                    )
                }
            }
        }
    }

    func stop() {
        task?.cancel()
        Task {
            await scanner?.stop()
        }
        isScanning = false
    }

    func moveToTrash(node: FileNode) {
        do {
            try FileManager.default.trashItem(at: node.url, resultingItemURL: nil)

            // Remove the node from the in-memory tree so the treemap updates.
            if let live = liveRoot, let updated = live.removingNode(at: node.url) {
                liveRoot = updated
                rebuildNavigationStack(against: updated)
            }
            if let res = result, let updated = res.root.removingNode(at: node.url) {
                result = ScanResult(root: updated, totalSize: updated.size, fileCount: res.fileCount, folderCount: res.folderCount)
                rebuildNavigationStack(against: updated)
            }
            if selectedNode?.url == node.url {
                selectedNode = nil
            }
            // Refresh the volume free space so the header updates live.
            selectedVolume?.refreshFreeSpace()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to move to Trash: \(error.localizedDescription)"
        }
    }

    private func rebuildNavigationStack(against newRoot: FileNode) {
        // Keep navigation stack entries that still exist in the updated tree.
        navigationStack = navigationStack.compactMap { newRoot.node(at: $0.url) }
    }

    func navigateBack() {
        guard !navigationStack.isEmpty else { return }
        let _ = withAnimation(.easeInOut(duration: 0.2)) {
            navigationStack.removeLast()
        }
    }

    func navigateToRoot() {
        let _ = withAnimation(.easeInOut(duration: 0.2)) {
            navigationStack.removeAll()
        }
    }
}

struct TreemapView: View {
    let root: FileNode
    @Binding var selectedNode: FileNode?
    @Binding var navigationStack: [FileNode]
    let isScanning: Bool
    let onDelete: (FileNode) -> Void

    private var currentRoot: FileNode { navigationStack.last ?? root }

    var body: some View {
        GeometryReader { geo in
            let rects = squarifyTreemap(
                node: currentRoot,
                x: 0,
                y: 0,
                width: geo.size.width,
                height: geo.size.height
            )
            ZStack(alignment: .topLeading) {
                ForEach(rects) { rect in
                    TreemapBlock(
                        rect: rect,
                        selectedNode: $selectedNode,
                        rootSize: currentRoot.size,
                        onNavigate: { node in
                            if node.isDirectory, !node.children.isEmpty {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    navigationStack.append(node)
                                }
                            } else if node.name == "Other" {
                                // Show aggregated small files in the same parent.
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    navigationStack.append(node)
                                }
                            }
                        },
                        onDelete: onDelete
                    )
                    .position(
                        x: rect.x + rect.width / 2,
                        y: rect.y + rect.height / 2
                    )
                }
            }
            .animation(.easeInOut(duration: 0.25), value: rects)
        }
    }
}

struct TreemapBlock: View {
    let rect: TreemapRect
    @Binding var selectedNode: FileNode?
    let rootSize: Int64
    let onNavigate: (FileNode) -> Void
    let onDelete: (FileNode) -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        let color = colorForNode(rect.node, depth: rect.level, totalSize: Double(rootSize))

        leafBody(color)
            .frame(width: rect.width, height: rect.height)
            .opacity(isHovered ? 0.92 : 1.0)
            .transition(.opacity.combined(with: .scale(scale: 0.85)))
            .contentShape(Rectangle())
            .onHover { hovering in
                isHovered = hovering
                if hovering { selectedNode = rect.node }
            }
            .onTapGesture {
                selectedNode = rect.node
                if rect.node.isDirectory || rect.node.name == "Other" {
                    onNavigate(rect.node)
                }
            }
            .contextMenu {
                Button("Show in Finder") {
                    NSWorkspace.shared.selectFile(rect.node.url.path, inFileViewerRootedAtPath: "")
                }
                if rect.node.isDirectory {
                    Button("Move Folder to Trash", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                } else {
                    Button("Move to Trash", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                }
            }
            .alert(rect.node.isDirectory ? "Move folder to Trash?" : "Move to Trash?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Move to Trash", role: .destructive) {
                    onDelete(rect.node)
                }
            } message: {
                Text("Move \"\(rect.node.name)\" (\(rect.node.formattedSize)) and all its contents to the Trash?")
            }
    }

    /// GrandPerspective leaf: flat colored block with centered label.
    private func leafBody(_ color: Color) -> some View {
        ZStack {
            Rectangle()
                .fill(color)
            Rectangle()
                .stroke(isHovered ? Color.white.opacity(0.9) : Color.primary.opacity(0.35), lineWidth: 1)

            if rect.width > 40 && rect.height > 18 {
                VStack(spacing: 1) {
                    Text(rect.node.name)
                        .font(.system(size: min(11, rect.height / 3), weight: .semibold))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if rect.height > 28 && rect.width > 60 {
                        Text(rect.node.formattedSize)
                            .font(.system(size: min(9, rect.height / 4)))
                            .opacity(0.85)
                    }
                }
                .foregroundStyle(colorScheme == .dark ? .white : .black)
                .padding(2)
            }
        }
    }
}

struct VolumeRow: View {
    let volume: Volume
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: "externaldrive.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 6) {
                    Text(volume.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("\(volume.formattedUsedSpace) used of \(volume.formattedSize)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    GeometryReader { geo in
                        let ratio = volume.size > 0 ? Double(volume.usedSpace) / Double(volume.size) : 0
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(.primary.opacity(0.1))
                            Rectangle()
                                .fill(Color.accentColor)
                                .frame(width: geo.size.width * ratio)
                        }
                    }
                    .frame(height: 6)
                    .cornerRadius(3)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(volume.formattedFreeSpace)")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    Text("free")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(.primary.opacity(0.04))
            .overlay(Rectangle().stroke(.primary.opacity(0.15), lineWidth: 1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
