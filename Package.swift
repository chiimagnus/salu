// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Salu",
    targets: [
        // GameCore: 纯 Swift 游戏逻辑库（禁止 print、禁止 UI）
        .target(
            name: "GameCore"
        ),
        // GameCLI: 命令行前端
        .executableTarget(
            name: "GameCLI",
            dependencies: ["GameCore"]
        ),
        // GameCoreTests: 单元测试（验证内部逻辑实现）
        .testTarget(
            name: "GameCoreTests",
            dependencies: ["GameCore"]
        ),
    ]
)
