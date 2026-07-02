// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "macSniffer",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "macSniffer", targets: ["macSniffer"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "macSniffer",
            path: "Sources",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
