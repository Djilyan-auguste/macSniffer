import Foundation
import AppKit

enum AuthorizationStatus: Equatable {
    case unknown
    case granted
    case denied
}

struct PermissionManager {
    static func checkFullDiskAccess() -> AuthorizationStatus {
        // Test a protected path. If we can read it, we likely have Full Disk Access.
        let protectedURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
        return canRead(path: protectedURL.path) ? .granted : .denied
    }

    private static func canRead(path: String) -> Bool {
        let file = fopen(path, "r")
        if file != nil {
            fclose(file)
            return true
        }
        return FileManager.default.fileExists(atPath: path)
    }

    static func openFullDiskAccessSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
        NSWorkspace.shared.open(url)
    }
}
