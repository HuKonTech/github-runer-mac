// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "github_mac",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(
            name: "GitHubRunnerMenu",
            targets: ["GitHubRunnerMenu"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "GitHubRunnerMenu"
        ),
    ]
)
