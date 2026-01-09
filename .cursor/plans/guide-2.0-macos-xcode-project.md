# 手把手：在本仓库中创建 macOS SwiftUI Xcode 工程，并复用 GameCore（Local Swift Package）- 2026-01-09

## 0. 你最终要达成的结构（推荐）

目标：**macOS App 用 Xcode 管理**（签名/i18n/资源最顺），而核心逻辑继续留在本仓库的 SwiftPM package 里。

推荐目录：

```
salu/                          # 本仓库根目录（已是 Swift Package）
  Package.swift
  Sources/
    GameCore/
    GameCLI/
  SaluMacApp/                  # 新增：Xcode macOS App 工程目录
    SaluMacApp.xcodeproj
    SaluMacApp/                # Xcode 自动生成的源码目录（App 入口、SwiftUI Views、Assets、Localizable.strings）
```

---

## 1. 前置条件

- **Xcode 版本**：建议 Xcode 15+（越新越好）
- **macOS 版本**：建议 macOS 13+（低版本也能做，但 SwiftUI/工具链限制会更多）
- **Apple Developer**：
  - 仅本地跑起来：不强制
  - 上架 App Store：需要 Apple Developer Program + App Store Connect（后续再做）

---

## 2. 创建 Xcode macOS SwiftUI App 工程（最小步骤）

### 2.1 新建工程

1. 打开 Xcode
2. 菜单 `File` → `New` → `Project...`
3. 选择：
   - 左侧 `macOS`
   - 模板选 `App`
4. 点击 `Next`

### 2.2 填写工程信息（建议填写）

- **Product Name**：`SaluMacApp`
- **Team**：
  - 先选 `None` 也可以（仅本地跑）
  - 若你已加入 Apple Developer Program，可先选你的 Team（后续签名更顺）
- **Organization Identifier**：例如 `com.yourcompany`
- **Bundle Identifier**：Xcode 会自动生成 `com.yourcompany.SaluMacApp`
- **Interface**：`SwiftUI`
- **Language**：`Swift`

点击 `Next`。

### 2.3 保存位置（关键）

把工程存到本仓库根目录下的新文件夹：

- 选择路径：`<repo>/SaluMacApp/`
- 勾选 `Create Git repository on my Mac` **不要勾**（因为我们已经在现有 repo 里）

点击 `Create`。

---

## 3. 让 Xcode App 复用本仓库的 `GameCore`（Add Local Package）

### 3.1 添加本地 Package 依赖

在 Xcode 打开 `SaluMacApp.xcodeproj` 后：

1. 菜单 `File` → `Add Packages...`
2. 左下角选择 `Add Local...`
3. 选择本仓库根目录（包含 `Package.swift` 的目录，例如 `.../salu/`）
4. 添加后，Xcode 会让你选择要加到哪个 target：
   - 勾选 `GameCore`
   - 点击 `Add Package`

> 你现在就能在 App 里 `import GameCore` 使用 `RunState/BattleEngine/...` 了。

### 3.2 在 SwiftUI 里验证能用 GameCore（最小代码）

打开 Xcode 自动生成的 `ContentView.swift`，把内容换成类似：

```swift
import SwiftUI
import GameCore

struct ContentView: View {
    var body: some View {
        let run = RunState.newRun(seed: 1)
        return VStack(alignment: .leading) {
            Text("玩家：\(run.player.name)")
            Text("HP：\(run.player.currentHP)/\(run.player.maxHP)")
            Text("金币：\(run.gold)")
        }
        .padding()
    }
}
```

然后按 `Cmd + R` 运行，确认窗口正常打开并显示数据。

---

## 4. 签名（Signing）怎么做（先让你跑起来，再谈上架）

### 4.1 仅本地运行（最简单）

- 你可以先不配 Team（`Signing & Capabilities` 里 Team = None）
- 只要能 Run，就说明工程与 package 依赖关系正确

### 4.2 未来上架 App Store（你后续要做的）

上架时建议走 Xcode 的标准流程：

1. `SaluMacApp` target → `Signing & Capabilities`
2. 勾选 `Automatically manage signing`
3. 选择 Team
4. 设置 Bundle Identifier（必须唯一）
5. `Product` → `Archive`
6. `Distribute App` → `App Store Connect`

> App Store 会要求一系列能力（常见是 App Sandbox），等你 P1/P2 跑通后再加即可。

---

## 5. i18n（本地化）怎么做（Xcode 的优势点）

最小落地方式：

1. 在 Xcode 工程里新增 `Localizable.strings`：
   - `File` → `New` → `File...` → `Strings File`
   - 命名 `Localizable.strings`
2. 选中该文件，在右侧 `File Inspector` 勾选 `Localize...`
3. 选择语言（例如 `English`）
4. SwiftUI 里用 `Text("key")`，并在 `Localizable.strings` 配置：

```text
"app.title" = "Salu";
```

然后 SwiftUI：

```swift
Text("app.title")
```

> 现阶段你可以先把 UI 文案本地化，`GameCore` 内的内容（卡牌/敌人描述）仍保持中文；后续要多语言再把“内容文本表”从纯逻辑层抽出去（注入式）。

---

## 6. 常见坑（提前避雷）

- **不要把 App 代码塞进 `Sources/GameCore`**：GameCore 必须保持纯逻辑，不导入 SwiftUI/AppKit。
- **不要在 App target 里直接改动 GameCore 的纯逻辑约束**：UI/持久化放在 App 或未来的 `SaluApp/SaluPersistence`。
- **Xcode 添加 Local Package 后报错**：
  - 通常是 Xcode 没有刷新 package graph
  - 解决：`File` → `Packages` → `Reset Package Caches`，然后重新 build

---

## 7. 下一步建议（按优先级）

- **P1**：Xcode 工程跑起来（已能 import GameCore）
- **P2**：把 UI 状态机抽到 `SaluApp`（SwiftPM library target），App 只写 SwiftUI Views
- **P3**：持久化抽到 `SaluPersistence`，App/未来 iOS 复用


