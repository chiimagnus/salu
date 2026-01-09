# Plan A（P1/P2/P3/P4）：新增 macOS SwiftUI 版本（尽量复用现有 GameCore；不再维护 CLI）- 2026-01-09

## 0. 目标与前提

### 0.1 目标

- 新增一个 **macOS App（SwiftUI）** 版本，采用 **ViewModel + View** 模式。
- **尽量复用**现有 `Sources/GameCore/` 的领域逻辑（战斗/冒险/地图/奖励/事件/商店/遗物等）。
- **CLI 版本视为冻结**：不再做功能维护，不为“让 CLI 更优雅”而付出重构成本。

### 0.2 必须遵守的现有约束

- `GameCore` 仍保持纯逻辑约束：不引入 UI，不读 stdin，不 `print()`（`History.swift` 例外允许 `Foundation`）。
- 依赖方向保持：App/CLI → GameCore（禁止反向依赖）。

---

## 1. 结论：是否需要重构？

- **不需要为了做 SwiftUI 版本而重构 GameCore**：它已经是干净的领域层，可直接被 macOS app 依赖。
- 需要新增的是 **应用层（App layer）**：把用户交互变成 Action，并驱动 `RunState/BattleEngine` 更新，同时产出 SwiftUI 可观察的状态（ViewState）。

因此本计划把“新 macOS app”拆成两部分：

- **领域层**：现有 `GameCore`（最大复用）
- **应用层**：新增 `SaluApp`（或 `GameApp`）模块：UI 无关的 ViewModel/State machine
- **UI 层**：新增 `SaluMacApp`（SwiftUI Views），依赖 `SaluApp`
- **持久化**：可选新增 `SaluPersistence`（复用现有 `GameCLI/Persistence` 代码或重写）

---

## 2. 推荐工程落地方式（你选择：先试方案 B）

你现在的选择是：**先试方案 B**，把 SwiftUI macOS app 直接作为 SwiftPM target 加到 `Package.swift` 里。

### 方案 B：在 `Package.swift` 新增 `SaluMacApp`（SwiftUI）executable target

- 好处：只用 SwiftPM（`swift build`/`swift run` 即可）
- 关键注意点（你提到的“非 macOS 过滤”）：
  - SwiftPM 没有“macOS-only target 不参与其他平台构建”的开关
  - 因此需要用 **条件编译**让该 target 在非 macOS 上也能编译（产出一个 stub main），从而保证非 macOS 上 `swift build` 仍能过

#### 非 macOS 如何“过滤”才不会挂（推荐做法：双 main 文件 + 条件编译）

在 `Sources/SaluMacApp/` 下放两个入口文件：

- `SaluMacAppMain.swift`（仅在可导入 SwiftUI 时编译）
- `SaluMacAppStubMain.swift`（仅在不可导入 SwiftUI 时编译）

原则：任何平台最终只能编译出 **一个** `@main`。

伪代码示意：

```swift
// SaluMacAppMain.swift
#if canImport(SwiftUI)
import SwiftUI
import GameCore

@main
struct SaluMacApp: App {
    var body: some Scene { WindowGroup { Text("Salu") } }
}
#endif
```

```swift
// SaluMacAppStubMain.swift
#if !canImport(SwiftUI)
@main
struct SaluMacAppStub {
    static func main() {
        // 非 macOS 环境下的占位，确保 swift build 仍然能过
        print("SaluMacApp 仅支持 macOS（SwiftUI）")
    }
}
#endif
```

> 这样：macOS 上会编译真正的 SwiftUI App；Linux/Windows 上会编译 stub，不会因为 `import SwiftUI` 失败导致全局构建失败。

#### 方案 B 的验证方式（每个 P 都做）

- macOS：`swift build` + `swift run SaluMacApp`
- 非 macOS（CI）：`swift build`（会构建 stub）

### 方案 A（备选）：Xcode app + 本仓库 package

如果后续发现 SwiftPM 的 SwiftUI App（方案 B）在打包/资源/签名/调试体验上卡住，再切换回方案 A（Xcode app）即可。

---

## 3. 分层（macOS app 内部的 ViewModel + View）

### 3.1 ViewModel（UI 无关，可复用）

建议在 SwiftPM 里新增 library target：`SaluApp`，并把 ViewModel 放在：

- `Sources/SaluApp/`

ViewModel 设计口径：

- 事件驱动：`reduce(action:)` 或 `send(_ action:)`
- 输出：`ViewState`（纯数据，不含 ANSI、不含 `Terminal`、不含 IO）
- 依赖：只依赖 `GameCore` + 一组协议（如 `RunSaving/HistoryStoring`），避免直接依赖“文件实现”

### 3.2 View（SwiftUI）

- `SaluMacApp` 的 SwiftUI Views：`ContentView` / `BattleView` / `MapView` / `RewardView` / `EventView` ...
- Views 只关心展示 ViewState，并把用户操作转换为 Action 发给 ViewModel。

---

## 4. Plan A（P1 / P2 / P3 / P4）

每个 P 都要求：

- **macOS 上可编译运行**（Xcode 或 xcodebuild）
- `GameCore` 的 `swift build` 仍然能过（不引入 UI 依赖到 GameCore）

---

## P1：搭出 macOS SwiftUI app 骨架 + 证明可直接复用 GameCore

### P1.1 交付内容

- 新增 `SaluMacApp`（SwiftUI）工程（或 app target）
- App 能启动并显示一个最小界面：
  - 按钮：开始新冒险（seed 可固定）
  - 展示：玩家基础信息（来自 `RunState.newRun(seed:)`）

### P1.2 关键实现点

- 直接 import `GameCore`
- `RunState.newRun(seed:)` 在 ViewModel 中创建 run
- View 展示：HP/金币/牌组数量/遗物数量

### P1.3 验证

- Xcode 运行 `SaluMacApp` 成功
- `swift build`（在仓库根目录）仍成功

---

## P2：新增 `SaluApp`（可复用 ViewModel）+ 基础战斗闭环

### P2.1 交付内容

- SwiftPM 新增 `SaluApp` library target（依赖 `GameCore`）
- `SaluMacApp` 使用 `SaluApp` 的 ViewModel，而不是直接在 View 里操作 `GameCore`
- 实现最小战斗闭环：
  - 从 run 进入一场战斗（用 EncounterPool 或固定敌人）
  - SwiftUI 显示战斗状态（玩家/敌人 HP、手牌、能量）
  - 支持：出牌、结束回合

### P2.2 验证

- Xcode 运行可打一场战斗到胜负
- `swift build` 成功
- （建议）`swift test`：为 `SaluApp` 加最小单测（Action → State）

---

## P3：冒险流程（地图/房间）+ 选择类界面（奖励/事件/商店/休息）

### P3.1 交付内容

- 在 `SaluApp` 中实现冒险状态机：
  - 地图选择节点（基于 `RunState.accessibleNodes / enterNode / completeCurrentNode`）
  - 房间流程：battle/elite/boss/event/shop/rest
- SwiftUI Views 对应展示与交互：
  - 地图：可选节点列表
  - 奖励：卡牌三选一或跳过（用 `RewardGenerator`）
  - 事件：展示 `EventOffer`，选择 option（含 follow-up）
  - 商店：展示 `ShopInventory`，购买/删牌
  - 休息：回血/升级卡牌

### P3.2 验证

- 能完成一段完整冒险（起点→战斗→奖励→…→Boss）
- `swift build` 仍成功

---

## P4：持久化（可选但推荐：最大化复用）

### P4.1 交付内容

- 新增 `SaluPersistence` library target（SwiftPM），提供：
  - Run 存档：基于 `RunSnapshot`
  - 战绩：基于 `BattleRecord`
  - 设置：showLog 等
- `SaluMacApp` 使用 `SaluPersistence` 注入到 `SaluApp`（协议化）

> 说明：可以直接复用现有 `Sources/GameCLI/Persistence/*` 的实现，迁移到 `Sources/SaluPersistence/`，并把类型改为 `public`（必要时）。

### P4.2 验证

- macOS app 可保存/继续冒险
- 不破坏 `GameCore` 纯逻辑约束
- `swift build` /（建议）`swift test` 成功

---

## 5. 后续（不在本 Plan A 的必做范围）

- iOS/iPadOS 版本：同样复用 `GameCore` + `SaluApp`
- 将 CLI 变成纯 debug harness（可选）
- CI：新增 macOS job 跑 `xcodebuild`，Linux job 仍跑 `swift build`（保持跨平台）


