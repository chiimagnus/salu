---
title: Plan A - visionOS + macOS GUI 原生实现（SwiftUI）
date: 2026-01-13
updated: 2026-01-14
architecture: Multiplatform App + 条件编译
---

# Plan A：visionOS + macOS GUI 原生实现方案（SwiftUI）

## 0. 目标与核心决策

### 目标

- 在本仓库新增一套**原生 App**（SwiftUI），同时提供：
  - **macOS App**：桌面窗口体验（键鼠友好）
  - **visionOS App**：窗口式 2D 体验优先，后续可扩展沉浸式（ImmersiveSpace）
- 逻辑与内容 **100% 复用 `GameCore`**；不破坏现有 CLI（`GameCLI`）的构建与测试。
- 对外验收：能完成完整一局（主菜单 → 地图推进 → 战斗/事件/商店/休息 → Boss → 结算），并有可复现的 seed 展示与导出。

### 核心决策

1. **CLI 与 Native Apps 视为独立产品线**
   - CLI 继续沿用 JSON 落盘（见 `.giithub/docs/本地存储说明.md`）
   - Native Apps 采用 Apple 原生持久化（首选 SwiftData；必要时混合 `@AppStorage`）
   - 默认不做存档互通（后续可选：通过 `RunSnapshot` 作为“交换格式”实现导入/导出）

2. **Native Apps（macOS/visionOS）采用 Multiplatform App 架构**
   - 单一 App Target 同时支持 macOS 和 visionOS（而非两个独立 Target）
   - 所有代码共享，平台差异用 `#if os(visionOS)` / `#if os(macOS)` 做细节适配
   - 这种架构对 AI 编程更友好（所有代码都是文本文件，无需手动在 Xcode 中勾选 Target Membership）

3. **UI 的“最小可用”策略**
   - 第一阶段先做 **window-based 2D UI**（visionOS 和 macOS 同构）
   - “沉浸式战斗/3D 卡牌”放到后续 P8，避免在核心流程未完成前引入 RealityKit 复杂度

4. **可复现性（Determinism）继续以 `GameCore` 规范为准**
   - UI 层不引入系统随机作为“玩法决策输入”
   - 所有房间内容生成（战斗遭遇/奖励/商店/事件）都基于 seed 派生（参考 `RewardGenerator` / `ShopInventory` / `EventGenerator` 的设计）

### 非目标（v0 不做）

- 不实现 iCloud/CloudKit 同步
- 不实现多人/联网
- 不实现跨端共享存档（macOS ↔ visionOS ↔ CLI）——只提供未来扩展点
- 不做完整美术资源/音效体系（先用 emoji / SF Symbols / 文本）

### 验收标准（每个 P 都要满足）

- SwiftPM 侧：`swift build && swift test` 通过（确保 `GameCLI`/`GameCore` 不受影响）
- Xcode 侧：
  - `SaluCRH` 能在 macOS 上编译并运行
  - `SaluCRH` 能在 visionOS Simulator 上编译并运行（同一 Target，切换 Destination）
- 行为侧：同 seed + 同选择路径，战斗/地图/奖励/事件/商店结果可复现（允许 UI 表现差异）

### 测试/验证命令参考

| 组件 | 命令 | 说明 |
|------|------|------|
| GameCore | `swift test --filter GameCoreTests` | SwiftPM |
| GameCLI | `swift test --filter GameCLITests` | SwiftPM |
| Native（编译 - macOS） | `xcodebuild -project SaluNative/SaluNative.xcodeproj -scheme SaluCRH -destination 'platform=macOS' build` | Xcodebuild |
| Native（编译 - visionOS） | `xcodebuild -project SaluNative/SaluNative.xcodeproj -scheme SaluCRH -destination 'platform=visionOS Simulator,name=Apple Vision Pro' build` | 同一 Target，切换 destination |

---

## 1. 调研范围（本次 plan 实际查过的文件）

> 说明：只列出**本次确实读过/检索过**、且会直接影响 Native App 设计的文件。

- `Package.swift`
- `README.md`
- `AGENTS.md`
- `Sources/GameCore/AGENTS.md`
- `Sources/GameCLI/AGENTS.md`
- `Sources/GameCore/Run/RunState.swift`
- `Sources/GameCore/Run/RunSnapshot.swift`
- `Sources/GameCore/Run/RunSaveVersion.swift`
- `Sources/GameCore/Battle/BattleEngine.swift`
- `Sources/GameCore/Battle/BattleState.swift`
- `Sources/GameCore/Actions.swift`
- `Sources/GameCore/History.swift`
- `Sources/GameCore/Persistence/RunSaveStore.swift`
- `Sources/GameCore/Persistence/BattleHistoryStore.swift`
- `Sources/GameCore/Cards/CardRegistry.swift`
- `Sources/GameCore/Cards/StarterDeck.swift`
- `Sources/GameCore/Map/RoomType.swift`
- `Sources/GameCore/Rewards/RewardGenerator.swift`（检索/对齐接口与 seed 派生策略）
- `Sources/GameCore/Rewards/GoldRewardStrategy.swift`（检索/对齐接口与 seed 派生策略）
- `Sources/GameCore/Shop/ShopInventory.swift`（检索/对齐接口与 seed 派生策略）
- `Sources/GameCore/Shop/ShopPricing.swift`（检索/对齐接口）
- `Sources/GameCore/Events/EventGenerator.swift`（检索/对齐接口与 seed 派生策略）
- `Sources/GameCore/Events/EventContext.swift`（检索/对齐接口）
- `Sources/GameCLI/GameCLI.swift`（参考现有“runLoop/battleLoop”流程形态）
- `Sources/GameCLI/Persistence/SaveService.swift`（参考 `RunSnapshot ↔ RunState` 转换）
- `Sources/GameCLI/Flow/RoomHandling.swift`
- `Sources/GameCLI/Flow/RoomHandlerRegistry.swift`
- `Sources/GameCLI/Rooms/Handlers/BattleRoomHandler.swift`（参考战斗房间：遭遇/奖励/日志/节点完成）
- `Sources/GameCLI/Rooms/Handlers/RestRoomHandler.swift`（参考休息房间：升级/对话/节点完成）
- `.giithub/docs/本地存储说明.md`
- `.giithub/docs/Salu游戏业务说明（玩法系统与触发规则）.md`

---

## 2. 现状与关键接口（与 UI 直接相关）

### 2.1 `RunState`（冒险全局状态）

已确认（`Sources/GameCore/Run/RunState.swift`）：

- 冒险状态里已经包含：
  - 玩家 `Entity`
  - 牌组 `[Card]`
  - 金币 `gold`
  - 遗物 `relicManager`
  - 消耗品 `consumables`（最多 3 槽）
  - 地图 `[MapNode]` + `currentNodeId`
  - `seed/floor/maxFloor/isOver/won`
- 冒险推进 API：
  - `accessibleNodes`
  - `enterNode(_:)`
  - `completeCurrentNode()`（Boss 完成后自动进入下一幕或结算）
  - `restAtNode()`
  - `apply(_ effect: RunEffect)`（事件/奖励可直接返回一组 `RunEffect` 给 UI 层应用）

### 2.2 `BattleEngine`（战斗引擎）

已确认（`Sources/GameCore/Battle/BattleEngine.swift`）：

- 入口：
  - `startBattle()`
  - `handleAction(_:)`（`PlayerAction.playCard(handIndex:targetEnemyIndex:)` / `.endTurn`）
- 观察点：
  - `state: BattleState`（hand/draw/discard/energy/enemies/isOver/playerWon）
  - `events: [BattleEvent]`（可用于 UI 日志/动效）
- 目标选择逻辑已内建：
  - 卡牌 `targeting == .singleEnemy` 时会强校验目标合法性，并通过 `.invalidAction` 反馈

### 2.3 存档交换格式：`RunSnapshot`

已确认（`Sources/GameCore/Run/RunSnapshot.swift`）：

- `RunSnapshot` 是 `Codable`，字段覆盖 Run 的核心状态：
  - `version/seed/floor/maxFloor/gold/mapNodes/currentNodeId/player/deck/relicIds/consumableIds/isOver/won`
- 版本策略（`RunSaveVersion`）目前为 **强制等版本**（`version == current` 才允许加载）

### 2.4 战斗历史：`BattleRecord`

已确认（`Sources/GameCore/History.swift`）：

- `BattleRecord` 是 `Codable`，含 `Date/UUID`，并支持多敌人记录
- `BattleRecordBuilder.build(from:seed:)` 可直接从 `BattleEngine` 构建记录

---

## 3. 总体架构（Multiplatform App + 条件编译）

> 关键点：
> 1. **不把 Apple-only 代码放进 SwiftPM 的 `Sources/`**，避免影响 Linux/Windows 构建
> 2. **使用 Multiplatform App 架构**，单一 Target 同时支持 macOS 和 visionOS
> 3. **平台差异通过 `#if os()` 条件编译处理**，而非创建多个 Target
> 4. **对 AI 编程友好**：所有代码都是文本文件，无需手动在 Xcode 中勾选 Target Membership

### 3.1 目录与工程形态

```
SaluNative/
├── SaluNative.xcodeproj
└── SaluCRH/                     # Multiplatform App（同时支持 macOS + visionOS）
    ├── SaluCRHApp.swift         # @main 入口
    ├── ContentView.swift        # 根视图（根据 AppRoute 切换）
    ├── AppRoute.swift           # 路由枚举
    ├── GameSession.swift        # 流程状态机
    ├── Views/                   # 共享 UI
    │   ├── MainMenuView.swift   # ✅ P2 已实现
    │   ├── MapView.swift        # ✅ P2 已实现
    │   ├── BattleView.swift     # P5 待实现
    │   ├── ShopView.swift       # P7 待实现
    │   ├── EventView.swift      # P6 待实现
    │   └── ...
    ├── ViewModels/              # 视图模型（桥接 GameCore）
    │   └── BattleSession.swift  # P5 待实现
    ├── Platform/                # 平台特有代码
    │   └── visionOS/            # visionOS 特有（ImmersiveSpace 等）
    ├── Persistence/             # SwiftData 模型（P3 待实现）
    │   ├── RunSaveEntity.swift
    │   └── BattleRecordEntity.swift
    ├── AGENTS.md                # 模块开发规范
    └── Assets.xcassets
```

`SaluNative.xcodeproj` 通过 “Add Local Package” 引入仓库根目录的 `Package.swift`，从而依赖 `GameCore`。

### 3.2 依赖方向

- `SaluCRH → GameCore` ✅
- `GameCore → (任何 App/UI/SwiftData)` ❌（保持纯逻辑层约束）
- `GameCLI ↔ Native Apps` ❌（互不依赖）

### 3.3 平台差异处理

使用条件编译处理平台差异：

```swift
// 示例：visionOS 特有的 ImmersiveSpace
#if os(visionOS)
import RealityKit

struct ImmersiveBattleView: View {
    var body: some View {
        RealityView { ... }
    }
}
#endif

// 示例：根据平台调整 UI
var body: some View {
    #if os(visionOS)
    // visionOS: 更大的点击目标
    CardView().frame(width: 200, height: 300)
    #else
    // macOS: 更紧凑的布局
    CardView().frame(width: 120, height: 180)
    #endif
}
```

### 3.4 Xcode 配置要点

在 Target 的 Build Settings 中配置 Supported Platforms：
- `SUPPORTED_PLATFORMS = macosx xros xrsimulator`

或在 Xcode UI 中：Target → General → Supported Destinations，添加 visionOS。

---

## 4. Native 持久化设计（SwiftData 优先）

### 4.1 目标

- 支持：
  - 单一 Run 存档（继续冒险）
  - 战斗历史（可追加、可清空、可统计）
  - 设置项（showLog 等）
- 支持测试：
  - in-memory SwiftData container（单元测试）
  - 可选：在 debug 下允许指定数据目录（便于复现/隔离）

### 4.2 推荐模型：**“索引字段 + JSON Blob”**（兼顾可查询与易演进）

> 解释：`RunSnapshot`/`BattleRecord` 本身已经是稳定的 `Codable` 结构。把它们作为 blob 存起来，可以极大降低 SwiftData 模型演进成本；同时抽出少量字段用于列表/排序/统计。

- `RunSaveEntity`
  - `id: UUID`
  - `updatedAt: Date`
  - `seed: UInt64`
  - `floor: Int`
  - `isOver: Bool`
  - `won: Bool`
  - `snapshotJSON: Data`（JSONEncoder 编码的 `RunSnapshot`）

- `BattleRecordEntity`
  - `id: UUID`
  - `timestamp: Date`
  - `seed: UInt64`
  - `won: Bool`
  - `turnsPlayed: Int`
  - `playerFinalHP: Int`
  - `totalDamageDealt: Int`
  - `recordJSON: Data`（JSONEncoder 编码的 `BattleRecord`）

### 4.3 `RunSnapshot ↔ RunState` 转换

- 直接参考并“移植” CLI 的转换逻辑（`Sources/GameCLI/Persistence/SaveService.swift`）
- 注意：
  - 还原时需要校验 `CardRegistry/RelicRegistry/ConsumableRegistry` 里是否存在对应 ID（否则视为损坏存档）
  - 版本策略沿用 `RunSaveVersion.isCompatible`

---

## 5. 运行时状态机（Shared）

### 5.1 顶层状态枚举（建议）

```
AppRoute
- mainMenu
- runMap(runState: RunState)
- roomStart(...)
- roomBattle(BattleSession)
- roomElite(BattleSession)
- roomBoss(BattleSession)
- rewardCard(offer: CardRewardOffer, goldEarned: Int, context: RewardContext)
- shop(inventory: ShopInventory, context: ShopContext)
- event(offer: EventOffer, context: EventContext)
- rest(...)
- runResult(won: Bool, snapshot: RunSnapshot?)
- history
- statistics
- settings
```

### 5.2 BattleSession（桥接 `BattleEngine` 与 SwiftUI）

- `BattleEngine` 本身不是 Observable，需要一层包装：
  - 每次执行 `handleAction` 后，把 `engine.state` 拷贝到 `@Published var state`
  - 把 `engine.events` flush 成 UI log（并在合适时机 `engine.clearEvents()`）

### 5.3 种子派生策略（与 GameCore 对齐）

- **奖励**：用 `RewardContext` + `GoldRewardStrategy` / `RewardGenerator`
- **商店**：用 `ShopContext` + `ShopInventory.generate`
- **事件**：用 `EventContext` + `EventGenerator.generate`
- **战斗遭遇**：
  - 参考 CLI 的做法（`BattleRoomHandler`）+ `ActXEncounterPool`
  - 建议把 `node.id` 加入 seed 派生，以避免同 row 多节点种子碰撞

---

## 6. UI 设计（跨 macOS / visionOS 的最小一致体验）

### 6.1 交互约定（统一）

- 任何平台都采用一致的“选择式”交互：
  - 选卡 →（若需要）选目标 → 出牌
  - 按钮：结束回合
  - 战斗结束自动进入奖励/返回地图
- UI 必须显式展示：
  - seed、floor、当前节点类型
  - 敌人列表的“槽位序号”（与 `targetEnemyIndex` 对齐）

### 6.2 平台差异适配

- **macOS**
  - 鼠标点击为主；可选：键盘数字键快捷出牌/选目标（对齐 CLI 的习惯，方便验收）
  - 可以做更紧凑的信息密度（侧边栏日志/遗物条）

- **visionOS**
  - 点击目标更大、间距更大；避免密集小按钮
  - 初期保持 2D window；后续再引入 ImmersiveSpace

---

## 7. 执行计划（按优先级 / 可交付）

### ✅P1（必须）：创建 Xcode 工程 + Multiplatform App，能引用 `GameCore`

**目标**

- `SaluCRH` 能在 macOS 和 visionOS 上编译，且能 `import GameCore`

**实现步骤**

- 新建 `SaluNative/SaluNative.xcodeproj`
- 添加一个 Multiplatform App Target：`SaluCRH`
- 配置 Supported Platforms 包含 macOS 和 visionOS
- 通过本地 package 依赖引入 `GameCore`
- 在入口页验证：

```swift
import GameCore
let _ = CardRegistry.require("strike").name
```

**验证**

- `swift build && swift test`（确保 SwiftPM 侧不受影响）
- `xcodebuild -project SaluNative/SaluNative.xcodeproj -scheme SaluCRH -destination 'platform=macOS' build`
- `xcodebuild -project SaluNative/SaluNative.xcodeproj -scheme SaluCRH -destination 'platform=visionOS Simulator,name=Apple Vision Pro' build`

**当前状态**：✅ macOS 已完成，visionOS 待配置 Supported Destinations

---

### ✅P2（必须）：实现 `GameSession`（最小状态机）+ 主菜单

**目标**

- 主菜单支持：新游戏（输入 seed 可选）、继续（若有存档）、设置、历史/统计入口

**验证**

- macOS 能导航到"新游戏 → 地图页"
- visionOS（配置 Supported Destinations 后）能导航到"新游戏 → 地图页"

---

### P3（必须）：SwiftData 落盘（RunSave + BattleHistory）

**目标**

- Run：自动保存、加载、清除
- BattleHistory：追加、加载、清空、统计（基础字段）

**实现要点**

- `RunSnapshot`/`BattleRecord` 以 JSON blob 存储
- 转换逻辑移植自 CLI `SaveService`（但不依赖 GameCLI）

**验证**

- 新游戏 → 退出到菜单 → 继续 → 状态恢复一致
- 打完一场战斗 → 历史里可见记录

---

### P4（重要）：地图页（RunMap）+ 节点选择 + 房间路由

**目标**

- 地图可视化（至少能看见 `accessibleNodes`）
- 选择节点后进入对应房间 UI（start/battle/rest/shop/event/elite/boss）

**实现要点**

- `RunState.accessibleNodes` / `enterNode` / `completeCurrentNode`

---

### P5（重要）：战斗房间（battle/elite/boss）完整跑通

**目标**

- 支持多敌人
- 出牌、目标选择、结束回合
- 战斗结束后：
  - 记录 `BattleRecord`
  - 更新 `RunState.updateFromBattle`
  - 发放金币与卡牌奖励（battle/elite）
  - elite/boss 额外：遗物奖励（可跳过）

**实现要点**

- 奖励与金币用 `RewardContext` + `GoldRewardStrategy` / `RewardGenerator`
- 遭遇生成参考 `ActXEncounterPool`（与 CLI 保持一致或更严格的 seed 派生）

---

### P6（重要）：事件房间（Event）+ follow-up 支持

**目标**

- 事件展示（名称/描述/选项）
- 选择选项后应用 `RunEffect`
- 支持二次选择（例如：`chooseUpgradeableCard`）

**实现要点**

- `EventGenerator.generate(context:)` → `EventOffer`
- follow-up 用二级 route（例如弹出卡牌选择 sheet）

---

### P7（重要）：商店房间（Shop）+ 删牌/消耗品槽位

**目标**

- 展示 5 张卡、3 遗物、3 消耗品、删牌服务
- 购买/金币不足提示
- 消耗品槽位满时不可购买

**实现要点**

- `ShopInventory.generate(context:)`
- 交易成功后修改 `RunState`（加卡/加遗物/加消耗品/删牌/扣金币）

---

### P8（优化）：visionOS 体验增强（不阻塞主流程）

- UI 间距与可点击面积调整
- 可选：ImmersiveSpace “战斗桌面”原型（只做展示，不影响战斗规则）

---

## 8. 风险清单（提前规避）

- SwiftData 对复杂类型（Dictionary 等）支持有限 → 使用 JSON blob + 索引字段方案规避
- `BattleEngine` 非线程安全（`@unchecked Sendable`） → 强制在 MainActor/单线程使用
- visionOS 输入“目标选择”易误触 → 采用两步式选择（先选卡再选敌人）并提供取消
- Xcode 工程引入后影响仓库整洁 → `.gitignore` 必须忽略 `xcuserdata/`、`DerivedData` 等

---

## 9. 进度记录

| P | 完成日期 | 验证命令 | 结果 |
|---|----------|----------|------|
| P1 | 2026-01-14 | `xcodebuild ... -scheme SaluCRH -destination 'platform=macOS' build` | ✅ macOS 通过 / ⏳ visionOS 待配置 |
| P2 | 2026-01-14 | `xcodebuild ... -scheme SaluCRH -destination 'platform=macOS' build` | ✅ macOS 通过（主菜单 + 地图页） |
| P3 | - | - | - |
| P4 | - | - | - |
| P5 | - | - | - |
| P6 | - | - | - |
| P7 | - | - | - |
| P8 | - | - | - |
