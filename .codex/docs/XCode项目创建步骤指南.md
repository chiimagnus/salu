# Salu Native Apps - Xcode 项目创建步骤指南

## 概述

本指南详细说明如何在 Xcode 中创建支持 visionOS + macOS 的原生应用项目，按照 plan P1 的要求实现。

## 前置条件

- Xcode 15.2+ (支持 visionOS)
- Swift 6.0+
- 已验证 `swift build && swift test` 正常工作

## 步骤 1: 创建根目录结构

在项目根目录创建 SaluNative 文件夹：

```bash
mkdir SaluNative
```

## 步骤 2: 在 Xcode 中创建项目

### 2.1 打开 Xcode 并创建新项目

1. 打开 Xcode
2. 选择 `File` → `New` → `Project...`
3. 选择 `App` 模板
4. 点击 `Next`

### 2.2 项目基本信息

填写项目信息：
- **Product Name**: `SaluNative`
- **Team**: 选择你的开发团队（或 None）
- **Organization Identifier**: `com.chiimagnus.salu`（或你自己的标识符）
- **Bundle Identifier**: `com.chiimagnus.salu.native`（会自动生成）
- **Interface**: `SwiftUI`
- **Language**: `Swift`
- **Platform**: `macOS`（暂时选择 macOS，后续添加 visionOS）

### 2.3 保存项目

- **Location**: 选择项目根目录的 `SaluNative` 文件夹
- **Create Git repository**: 取消勾选（因为已经在项目根目录有 git）
- **Add to**: 选择 `Don't add to any project or workspace`
- 点击 `Create`

## 步骤 3: 添加 visionOS Target

### 3.1 添加新 Target

1. 在 Xcode 左侧项目导航中，选择项目根节点 `SaluNative`
2. 点击底部 `+` 按钮或 `File` → `New` → `Target...`
3. 选择 `App` 模板
4. 点击 `Next`

### 3.2 visionOS App 配置

填写信息：
- **Product Name**: `SaluVisionApp`
- **Team**: 同上
- **Organization Identifier**: 同上
- **Bundle Identifier**: `com.chiimagnus.salu.native.vision`（会自动生成）
- **Interface**: `SwiftUI`
- **Language**: `Swift`
- **Platform**: `visionOS`
- **Minimum Deployments**: `1.0`

点击 `Finish`

## 步骤 4: 添加共享 Framework Target

### 4.1 添加新 Target

1. 选择项目根节点
2. 点击 `+` 按钮或 `File` → `New` → `Target...`
3. 选择 `Framework` 模板
4. 点击 `Next`

### 4.2 Framework 配置

填写信息：
- **Product Name**: `SaluNativeKit`
- **Team**: 同上
- **Organization Identifier**: 同上
- **Bundle Identifier**: `com.chiimagnus.salu.native.kit`（会自动生成）
- **Language**: `Swift`
- **Platforms**: 勾选 `macOS` 和 `visionOS`
- **Minimum Deployments**:
  - macOS: `14.0`
  - visionOS: `1.0`

点击 `Finish`

## 步骤 5: 配置 Package 依赖

### 5.1 添加本地 Package

1. 在项目导航中选择项目根节点 `SaluNative`
2. 选择 `SaluNative` 项目（不是某个 target）
3. 点击顶部 `Package Dependencies` 标签
4. 点击 `+` 按钮添加依赖
5. 选择 `Add Local...`
6. 选择项目根目录的 `Package.swift` 文件
7. 点击 `Add Package`

### 5.2 验证依赖添加

在 Package Dependencies 列表中应该能看到：
- Salu (Local) - 包含 GameCore 等

## 步骤 6: 配置 Target 依赖关系

### 6.1 macOS App 依赖配置

1. 选择项目根节点
2. 选择 `SaluMacApp` target
3. 点击 `General` 标签
4. 在 `Frameworks, Libraries, and Embedded Content` 部分：
   - 点击 `+` 按钮
   - 选择 `SaluNativeKit`
   - 点击 `Add`

### 6.2 visionOS App 依赖配置

1. 选择 `SaluVisionApp` target
2. 重复上述步骤，添加 `SaluNativeKit` 依赖

### 6.3 Framework 依赖配置

1. 选择 `SaluNativeKit` target
2. 在 `Package Dependencies` 部分确保有 `Salu` package
3. 在 `Frameworks, Libraries, and Embedded Content` 部分确保链接了 `GameCore`

## 步骤 7: 创建基本的代码结构

### 7.1 重命名默认文件

将自动创建的文件重命名以符合命名规范：

1. `SaluNativeApp.swift` → `SaluMacApp.swift`（macOS）
2. `SaluVisionAppApp.swift` → `SaluVisionApp.swift`（visionOS）

### 7.2 创建共享代码目录结构

在 `SaluNativeKit` target 中创建以下目录结构：

```
SaluNativeKit/
├── Models/
├── ViewModels/
├── Views/
├── Services/
└── Resources/
```

### 7.3 添加验证代码

在 `SaluNativeKit` 中创建一个验证文件：

```swift
// SaluNativeKit/Verification.swift
import GameCore

public struct Verification {
    public static func verifyGameCoreAccess() -> Bool {
        // 验证能访问 GameCore
        let strikeCard = CardRegistry.get(CardID("strike"))
        return strikeCard != nil
    }
}
```

在两个 App 的入口文件中添加验证：

```swift
// SaluMacApp.swift 和 SaluVisionApp.swift
import SwiftUI
import SaluNativeKit

@main
struct SaluMacApp: App {  // 或 SaluVisionApp
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack {
            if Verification.verifyGameCoreAccess() {
                Text("✅ GameCore 访问成功")
                    .foregroundColor(.green)
            } else {
                Text("❌ GameCore 访问失败")
                    .foregroundColor(.red)
            }
            Text("Salu Native App")
        }
        .padding()
    }
}
```

## 步骤 8: 配置构建设置

### 8.1 Swift 版本设置

1. 选择项目根节点
2. 选择各个 target
3. 在 `Build Settings` 中搜索 `Swift Language Version`
4. 设置为 `6.0`

### 8.2 Swift Concurrency 设置

在 `Build Settings` 中：
- `Swift Language Version`: `6.0`
- `Strict Concurrency Checking`: `Complete`

## 步骤 9: 测试编译

### 9.1 构建所有 target

在 Xcode 中：

1. 选择 `SaluMacApp` scheme
2. `Product` → `Build` (⌘B)
3. 切换到 `SaluVisionApp` scheme
4. `Product` → `Build` (⌘B)
5. 切换到 `SaluNativeKit` scheme
6. `Product` → `Build` (⌘B)

### 9.2 运行验证

1. 选择 `SaluMacApp` scheme
2. `Product` → `Run` (⌘R)
3. 验证界面显示 "✅ GameCore 访问成功"

## 步骤 10: 命令行验证

在项目根目录运行以下命令验证：

```bash
# 确保 SwiftPM 不受影响
swift build && swift test

# macOS App 编译
xcodebuild -project SaluNative/SaluNative.xcodeproj -scheme SaluMacApp -destination 'platform=macOS' build

# visionOS App 编译（需要 visionOS Simulator）
xcodebuild -project SaluNative/SaluNative.xcodeproj -scheme SaluVisionApp -destination 'platform=visionOS Simulator,name=Apple Vision Pro' build
```

## 常见问题

### Q: visionOS Simulator 不存在
A: 在 Xcode 中：`Xcode` → `Settings` → `Platforms` → 下载 visionOS Platform

### Q: Package 依赖解析失败
A: 确保 Package.swift 在项目根目录，且路径正确

### Q: 编译错误 "No such module 'GameCore'"
A: 检查 Framework target 的 Package Dependencies 是否正确添加了 Salu package

### Q: Swift 版本不匹配
A: 确保所有 target 的 Swift Language Version 都设置为 6.0

## 下一步

完成 P1 后，可以继续 P2：实现 GameSession 和主菜单界面。

## 文件结构预览

```
SaluNative/
├── SaluNative.xcodeproj
├── SaluMacApp/           # macOS App Target
│   ├── SaluMacApp.swift
│   ├── ContentView.swift
│   └── ...
├── SaluVisionApp/        # visionOS App Target
│   ├── SaluVisionApp.swift
│   ├── ContentView.swift
│   └── ...
└── SaluNativeKit/        # 共享 Framework
    ├── Verification.swift
    ├── Models/
    ├── ViewModels/
    ├── Views/
    ├── Services/
    └── Resources/
```