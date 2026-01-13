# Xcode 添加本地 Package 依赖指南

> 参考: [Apple Developer - Adding package dependencies to your app](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app/)
> 参考: [Apple Developer - Organizing your code with local packages](https://developer.apple.com/documentation/xcode/organizing-your-code-with-local-packages/)

本指南说明如何在 `SaluNative.xcodeproj` 中添加仓库根目录的 `GameCore` 模块作为依赖。

---

## 前置条件

- 已创建 `SaluNative/SaluNative.xcodeproj`
- 已存在 `SaluMacApp` 和 `SaluVisionApp` 两个 Target
- 仓库根目录有 `Package.swift`，其中定义了 `GameCore` Target

---

## 方法一：通过拖拽添加本地 Package（推荐 ✅）

这是 Apple 文档推荐的最简单方式。

### 步骤 1：打开 Finder 和 Xcode

1. 打开 Finder，导航到仓库根目录（包含 `Package.swift` 的目录）
2. 打开 `SaluNative/SaluNative.xcodeproj`

### 步骤 2：拖拽 Package 目录到 Xcode

1. 在 Finder 中，找到仓库根目录（即 `Package.swift` 所在的父目录）
2. 将整个目录**拖拽**到 Xcode 左侧 Project Navigator 中
3. 在弹出的对话框中：
   - 确保 **Copy items if needed** 是**未勾选**的状态
   - 勾选 **Add to targets**：选择 **SaluMacApp** 和 **SaluVisionApp**
   - 点击 **Finish**

### 步骤 3：验证

Package 添加成功后，在 Project Navigator 中会出现该 Package，你可以展开查看 `Sources/GameCore` 等内容。

---

## 方法二：通过菜单添加（File → Add Package Dependencies）

### 步骤 1：打开添加 Package 界面

菜单路径：**File → Add Package Dependencies...**

### 步骤 2：添加本地 Package

1. 在弹出的搜索窗口中，**不要输入 URL**
2. 点击左下角的 **"Add Local..."** 按钮
3. 在文件选择器中，选择仓库根目录（包含 `Package.swift` 的目录）
4. 点击 **"Open"** 或 **"Add Package"**

### 步骤 3：选择 Package Product 和 Target

这一步非常重要！在弹出的 "Choose Package Products" 对话框中：

1. 你会看到 Package 的 Products 列表（如 `GameCore`、`GameCLI`）
2. **在右侧 "Add to Target" 列**，选择你要链接的 Target：
   - 对于 `GameCore`：选择 **SaluMacApp** 
   - 如果需要添加到多个 Target，需要重复此步骤或稍后手动添加
3. 点击 **"Add Package"**

> **注意**：如果在这一步没有选择 Target，Package 会被添加到项目但不会链接到任何 Target，导致 `import GameCore` 失败。

---

## 方法三：手动将 Package Product 链接到 Target

如果 Package 已添加但未链接到 Target（即你已经能在 Project Navigator 看到 Package，但编译报 `No such module`），使用此方法。

### 通过 General 标签页

1. 点击项目根节点 **SaluNative**（蓝色图标）
2. 在 **TARGETS** 列表中选择 **SaluMacApp**
3. 点击 **General** 标签页
4. 滚动到 **"Frameworks, Libraries, and Embedded Content"** 部分
5. 点击 **"+"** 按钮
6. 在弹出列表中，找到并选择 **GameCore**（应该在列表中显示）
7. 点击 **Add**
8. 对 **SaluVisionApp** Target 重复步骤 2-7

### 通过 Build Phases 标签页（备选）

1. 选择 Target（如 `SaluMacApp`）
2. 点击 **Build Phases** 标签页
3. 展开 **"Link Binary With Libraries"**
4. 点击 **"+"**
5. 选择 **GameCore**，点击 **Add**
6. 对另一个 Target 重复

---

## 验证配置

### 验证 1：检查 Project Navigator

在左侧 Project Navigator 中，你应该能看到：

```
SaluNative
├── SaluMacApp/
├── SaluVisionApp/
├── Packages/
│   └── RealityKitContent/
└── Salu (local)              ← 本地 Package
    ├── Sources/
    │   ├── GameCore/         ← GameCore 模块
    │   └── GameCLI/
    └── Package.swift
```

### 验证 2：检查 Frameworks 是否已链接

1. 点击项目根节点 **SaluNative**
2. 选择 **SaluMacApp** Target
3. 点击 **General** → 滚动到 **Frameworks, Libraries, and Embedded Content**
4. 确认列表中有 **GameCore**

### 验证 3：编译测试

编辑 `SaluMacApp/ContentView.swift`，添加 `import GameCore`，然后 `Cmd + B` 编译。

如果编译成功，说明配置完成！

---

## 问题排查

### 问题：Package 已添加但 `import GameCore` 报错 "No such module"

**原因**：Package 添加到了项目，但未链接到 Target。

**解决**：按照"方法三"将 GameCore 手动添加到 Target 的 Frameworks。

### 问题：Frameworks 列表中找不到 GameCore

**可能原因 1**：Package.swift 没有定义 GameCore 为 library product。

检查根目录的 `Package.swift`，确保有类似：
```swift
products: [
    .library(name: "GameCore", targets: ["GameCore"]),
]
```

如果 `Package.swift` 只有 `targets` 没有 `products`，需要添加 products。

**可能原因 2**：Xcode 缓存问题。

尝试：`File → Packages → Reset Package Caches`，然后重新编译。

### 问题：visionOS Target 编译失败

确保 `GameCore` 是纯 Swift 代码，不包含平台特定 API（如 AppKit/UIKit）。

---

## 命令行验证（可选）

```bash
# 验证 SwiftPM 侧不受影响
swift build && swift test

# 验证 macOS App 编译
xcodebuild -project SaluNative/SaluNative.xcodeproj \
  -scheme SaluMacApp \
  -destination 'platform=macOS' \
  build

# 验证 visionOS App 编译
xcodebuild -project SaluNative/SaluNative.xcodeproj \
  -scheme SaluVisionApp \
  -destination 'platform=visionOS Simulator,name=Apple Vision Pro' \
  build
```

---

## 下一步

完成 P1 后，可以继续 P2：实现 `GameSession`（最小状态机）+ 主菜单。参考 `.codex/plans/visionOS + macOS GUI 原生实现方案（SwiftUI）.md` 中的详细规划。
