import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()

    var body: some View {
        VStack(spacing: 0) {
            headerBar

            if viewModel.isScanning {
                ProgressView("Scanning: \(viewModel.scannedItems) items • \(viewModel.currentPath)")
                    .padding()
            } else if viewModel.errorMessage != nil {
                errorView
            } else if let result = viewModel.result {
                TreemapView(result: result, selectedNode: $viewModel.selectedNode)
            } else {
                welcomeView
            }

            if let selected = viewModel.selectedNode {
                HStack {
                    Text(selected.name)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(selected.formattedSize)
                        .monospacedDigit()
                }
                .padding(8)
                .background(Color.gray.opacity(0.2))
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }

    private var headerBar: some View {
        HStack {
            Button("Select Folder…") {
                viewModel.selectFolder()
            }
            .disabled(viewModel.isScanning)

            if let result = viewModel.result {
                Text("\(result.root.name) • \(result.root.formattedSize)")
                    .font(.headline)
                Spacer()
                Text("\(result.fileCount) files, \(result.folderCount) folders")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Spacer()
                Text("macSniffer — inspired by SpaceSniffer")
                    .font(.headline)
                Spacer()
            }

            Button("Stop") {
                viewModel.stop()
            }
            .disabled(!viewModel.isScanning)
        }
        .padding()
        .background(Color.black.opacity(0.1))
    }

    private var welcomeView: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("Select a folder or disk to visualize disk usage")
                .font(.title2)
            Button("Choose Folder…") {
                viewModel.selectFolder()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var errorView: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.red)
            Text(viewModel.errorMessage ?? "Unknown error")
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

@MainActor
final class AppViewModel: ObservableObject {
    @Published var result: ScanResult?
    @Published var isScanning = false
    @Published var scannedItems = 0
    @Published var currentPath = ""
    @Published var errorMessage: String?
    @Published var selectedNode: FileNode?

    private var scanner: DiskScanner?
    private var task: Task<Void, Never>?

    func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Scan"
        panel.title = "Choose a folder to scan"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        startScan(url: url)
    }

    func startScan(url: URL) {
        task?.cancel()
        result = nil
        errorMessage = nil
        selectedNode = nil
        isScanning = true
        scannedItems = 0

        let newScanner = DiskScanner()
        scanner = newScanner

        let progressBox = SendableBox(value: self)

        task = Task { [weak self] in
            let scanResult = await newScanner.scan(url: url) { progress in
                Task { @MainActor in
                    progressBox.value?.scannedItems = progress.scanned
                    progressBox.value?.currentPath = (progress.currentPath as NSString).lastPathComponent
                }
            }

            Task { @MainActor [weak self] in
                self?.isScanning = false
                if let scanResult {
                    self?.result = scanResult
                } else {
                    self?.errorMessage = "Scan failed or was cancelled."
                }
            }
        }
    }

    func stop() {
        scanner?.stop()
        task?.cancel()
        isScanning = false
    }
}

final class SendableBox<T: AnyObject>: @unchecked Sendable {
    weak var value: T?
    init(value: T) { self.value = value }
}

struct TreemapView: View {
    let result: ScanResult
    @Binding var selectedNode: FileNode?

    var body: some View {
        GeometryReader { geo in
            let rects = squarifyTreemap(
                node: result.root,
                x: 0,
                y: 0,
                width: geo.size.width,
                height: geo.size.height
            )
            ZStack(alignment: .topLeading) {
                ForEach(rects) { rect in
                    TreemapBlock(rect: rect, selectedNode: $selectedNode)
                        .position(
                            x: rect.x + rect.width / 2,
                            y: rect.y + rect.height / 2
                        )
                }
            }
        }
    }
}

struct TreemapBlock: View {
    let rect: TreemapRect
    @Binding var selectedNode: FileNode?

    var body: some View {
        let color = colorForSwift(rect.node)
        Rectangle()
            .foregroundStyle(color)
            .overlay(
                Rectangle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
            )
            .frame(width: rect.width, height: rect.height)
            .overlay(
                Group {
                    if rect.width > 40 && rect.height > 20 {
                        Text(rect.node.name)
                            .font(.system(size: min(12, rect.height / 3)))
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .foregroundStyle(.white)
                            .padding(2)
                    }
                },
                alignment: .topLeading
            )
            .onHover { hovering in
                if hovering { selectedNode = rect.node }
            }
            .onTapGesture {
                selectedNode = rect.node
            }
    }

    private func colorForSwift(_ node: FileNode) -> Color {
        let hue = (Double(node.depth) * 47.0 + 200).truncatingRemainder(dividingBy: 360) / 360.0
        return Color(hue: hue, saturation: 0.7, brightness: 0.55)
    }
}
