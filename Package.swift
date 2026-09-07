// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Sakuin",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Sakuin", targets: ["Sakuin"])
    ],
    dependencies: [
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.4.1")
    ],
    targets: [
        .executableTarget(name: "Sakuin", dependencies: [
            .product(name: "MarkdownUI", package: "swift-markdown-ui")
        ]),
        .testTarget(name: "SakuinTests", dependencies: ["Sakuin"])
    ]
)
