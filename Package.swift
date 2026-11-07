// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ShowHiddenFiles",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ShowHiddenFiles", targets: ["ShowHiddenFiles"])
    ],
    targets: [
        .executableTarget(
            name: "ShowHiddenFiles",
            path: "Sources/ShowHiddenFiles"
        )
    ]
)
