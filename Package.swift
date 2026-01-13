// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Salu",
    platforms: [
        .macOS(.v14),
        .visionOS(.v2),
    ],
    products: [
        // GameCore: 暴露为 library，供 Native Apps（macOS/visionOS）依赖
        .library(
            name: "GameCore",
            targets: ["GameCore"]
        ),
    ],
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
        // GameCLITests: GameCLI 白盒单元测试（对 SaveService/HistoryService 等可注入组件做断言）
        .testTarget(
            name: "GameCLITests",
            dependencies: ["GameCLI", "GameCore"]
        ),
        // GameCLIUITests: 使用 XCTest + Process 对 GameCLI 做黑盒「UI」测试（替代 sh 脚本）
        .testTarget(
            name: "GameCLIUITests",
            dependencies: ["GameCore"]
        ),
    ]
)
