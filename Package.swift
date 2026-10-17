// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "quicknote",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "quicknote", targets: ["quicknote"])
    ],
    targets: [
        .executableTarget(name: "quicknote", path: "Sources/Notepad")
    ]
)
