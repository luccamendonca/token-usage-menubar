// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TokenUsageMenubar",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "TokenUsageMenubar",
            path: "ClaudeUsageToolbar",
            exclude: [
                "Info.plist",
                "ClaudeUsageToolbar.entitlements",
            ]
        ),
    ]
)
