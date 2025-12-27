// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "iClaudius",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "iClaudius", targets: ["iClaudius"])
    ],
    targets: [
        .executableTarget(
            name: "iClaudius",
            path: "Sources"
        )
    ]
)
