import SwiftUI
import AppKit

@main
struct macSnifferApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
                .background(WindowAccessor())
        }
        .defaultSize(width: 900, height: 700)
        .windowResizability(.contentSize)
    }
}

struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                configureWindow(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    private func configureWindow(_ window: NSWindow) {
        let gold = NSColor(red: 0.99, green: 0.86, blue: 0.40, alpha: 1.0)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .visible
        window.backgroundColor = gold
    }
}
