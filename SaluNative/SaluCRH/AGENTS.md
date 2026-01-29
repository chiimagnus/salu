# SaluCRH 模块开发规范

SaluCRH 是 Salu 的原生 App 前端，采用 Multiplatform SwiftUI 架构，同时支持 macOS 和 visionOS。

## 模块职责

- **UI 层**：SwiftUI 视图、动画、用户交互
- **状态管理**：GameSession 状态机、AppRoute 路由
- **持久化**：SwiftData 存档、战斗历史
- **平台适配**：通过 `#if os()` 处理 macOS/visionOS 差异

## 依赖关系

```
SaluCRH → GameCore ✅
GameCore → SaluCRH ❌（禁止反向依赖）
GameCLI ↔ SaluCRH ❌（互不依赖）
```

**核心原则**：所有游戏逻辑来自 `GameCore`，本模块只负责 UI 展示和用户交互。

## 平台支持

- **macOS** 14.0+（当前支持 ✅）
- **visionOS** 2.0+（配置中）

使用条件编译处理平台差异：

```swift
#if os(visionOS)
import RealityKit
// visionOS 特有代码（如 ImmersiveSpace）
#elseif os(macOS)
// macOS 特有代码
#endif
```

## 目录结构

```
SaluCRH/
├── SaluCRHApp.swift           # @main 入口
├── ContentView.swift          # 根视图（根据 AppRoute 切换）
├── GameSession.swift          # 流程状态机
├── AppRoute.swift             # 路由枚举
├── Views/                     # SwiftUI 视图
│   ├── MainMenuView.swift
│   ├── MapView.swift
│   ├── BattleView.swift
│   ├── ShopView.swift
│   ├── EventView.swift
│   └── ...
├── ViewModels/                # 视图模型（桥接 GameCore）
│   └── BattleSession.swift    # 包装 BattleEngine
├── Persistence/               # SwiftData 模型
│   ├── RunSaveEntity.swift
│   └── BattleRecordEntity.swift
├── Platform/                  # 平台特有代码
│   └── visionOS/
│       └── ImmersiveView.swift
└── Assets.xcassets
```

## 核心类型

### AppRoute（路由枚举）

```swift
enum AppRoute {
    case mainMenu
    case runMap(runState: RunState)
    case battle(BattleSession)
    case shop(ShopInventory)
    case event(EventOffer)
    case rest
    case result(won: Bool)
    case history
    case settings
}
```

### GameSession（状态机）

```swift
@Observable
class GameSession {
    var route: AppRoute = .mainMenu
    var runState: RunState?
    
    func startNewGame(seed: UInt64?) { ... }
    func continueGame() { ... }
    func enterNode(_ node: MapNode) { ... }
}
```

### BattleSession（战斗桥接）

包装 `BattleEngine`，将其转换为 SwiftUI 可观察状态：

```swift
@Observable
class BattleSession {
    private let engine: BattleEngine
    var state: BattleState { engine.state }
    var events: [BattleEvent] { engine.events }
    
    func playCard(handIndex: Int, targetIndex: Int?) { ... }
    func endTurn() { ... }
}
```

## GameCore 集成

### 导入与使用

```swift
import GameCore

// 访问卡牌注册表
let strike = CardRegistry.require("strike")

// 创建冒险状态
let runState = RunState(seed: 12345)

// 创建战斗引擎
let engine = BattleEngine(...)
engine.startBattle()
```

### 关键 GameCore 类型

| 类型 | 用途 |
|------|------|
| `RunState` | 冒险全局状态 |
| `BattleEngine` | 战斗引擎 |
| `BattleState` | 战斗快照 |
| `MapNode` | 地图节点 |
| `Card` | 卡牌实例 |
| `Entity` | 玩家/敌人实体 |
| `RunSnapshot` | 存档格式 |
| `BattleRecord` | 战斗记录 |

### 种子与可复现性

所有随机内容必须通过 `GameCore` 的 seed 派生机制生成，UI 层不引入额外随机源：

```swift
// ✅ 正确：使用 GameCore 的生成器
let rewards = RewardGenerator.generate(context: rewardContext)
let shop = ShopInventory.generate(context: shopContext)
let event = EventGenerator.generate(context: eventContext)

// ❌ 错误：UI 层使用系统随机
let randomCard = deck.randomElement()  // 禁止
```

## SwiftData 持久化

### 模型设计

采用 "索引字段 + JSON Blob" 策略：

```swift
@Model
final class RunSaveEntity {
    var id: UUID
    var updatedAt: Date
    var seed: UInt64
    var floor: Int
    var isOver: Bool
    var won: Bool
    var snapshotJSON: Data  // JSONEncoder(RunSnapshot)
}
```

### 转换逻辑

参考 CLI 的 `SaveService`，实现 `RunSnapshot ↔ RunState` 转换。

## UI 规范

### 交互约定

- 选卡 →（若需要）选目标 → 出牌
- 战斗结束自动进入奖励/返回地图
- 必须显示：seed、floor、当前节点类型

### 平台差异

```swift
var body: some View {
    #if os(visionOS)
    // visionOS: 更大的点击目标
    CardView()
        .frame(width: 200, height: 300)
    #else
    // macOS: 更紧凑的布局
    CardView()
        .frame(width: 120, height: 180)
    #endif
}
```

## 构建与验证

验证原则：只改 `SaluNative/`（SwiftUI/SwiftData/UI）时，至少跑一次 `xcodebuild ... build`；无需强制跑 `swift test`（除非同时改了 `Sources/**/*.swift` 或 `Package.swift`）。

```bash
# macOS
xcodebuild -project SaluNative/SaluNative.xcodeproj \
  -scheme SaluCRH \
  -destination 'platform=macOS' \
  build

# visionOS (配置 Supported Destinations 后)
xcodebuild -project SaluNative/SaluNative.xcodeproj \
  -scheme SaluCRH \
  -destination 'platform=visionOS Simulator,name=Apple Vision Pro' \
  build
```

## 构建失败排查指南

**重要**：编译错误通常是因为 GameCore API 使用不正确。遇到构建失败时：

1. **查看 GameCore 源码**：错误提示的类型（如 `RunState`、`Entity`、`MapNode` 等）都定义在 `Sources/GameCore/` 中
2. **常见 API 差异**：
   - `RunState.newRun(seed:)` - 创建新冒险（不是直接 `init(seed:)`）
   - `Entity.currentHP` / `Entity.maxHP` - 注意大小写
   - `MapNode.roomType` - 不是 `type`
   - `RelicManager.all` - 获取所有遗物 ID（不是 `relics`）
   - `ConsumableID` 是 ID 类型，通过 `ConsumableRegistry.require()` 获取定义
3. **技术文档**：完整的 GameCore API 参考见 [GameCore 规范](../../Sources/GameCore/AGENTS.md)
## 禁止事项

- ❌ 在 View 中直接操作 `BattleEngine`（必须通过 `BattleSession`）
- ❌ 引入 UI 层随机源（所有随机通过 GameCore seed 派生）
- ❌ 依赖 `GameCLI`（两者互不依赖）
- ❌ 修改 `GameCore` 来适配 UI（GameCore 保持纯逻辑）
- ❌ 使用单例 ViewModel（使用依赖注入）
- ❌ 猜测 API - 遇到不确定的类型/属性，先查看 GameCore 源码

## 参考文档
- [总体方案](<../../.giithub/plans/visionOS + macOS GUI 原生实现方案（SwiftUI）.md>)
- [GameCore 规范](../../Sources/GameCore/AGENTS.md)
