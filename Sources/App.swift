import SwiftUI

@main
struct macSnifferApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 900, height: 700)
        .windowResizability(.contentSize)
    }
}
