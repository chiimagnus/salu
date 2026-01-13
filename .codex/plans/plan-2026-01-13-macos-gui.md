---
title: Plan A - macOS GUI 原生实现
date: 2026-01-13
---

# Plan A：macOS GUI 原生实现方案

## 0. 目标与核心决策

### 目标

创建一个全新的 macOS App（`SaluMacApp`），使用 macOS 原生技术栈实现完整的游戏体验。

### 核心决策

1. **CLI 和 GUI 是独立的两个产品**：
   - CLI 继续使用 JSON 文件存储（`run_save.json`、`battle_history.json` 等）
   - GUI 使用 macOS 原生技术（SwiftData、`@AppStorage` 等）
   - 两者的存档**不互通**

2. **共享代码**：
   - 仅共享 `GameCore`（纯逻辑层：规则/状态/引擎/Definition+Registry）
   - GUI 完全重写持久化层、流程层、UI 层

3. **技术栈**：
   - UI：SwiftUI
   - 持久化：SwiftData
   - 设置：`@AppStorage` / UserDefaults
   - 随机种子：继续使用 `GameCore.SeededRNG`

### 非目标（不做什么）

- 不修改 `GameCore` 的任何约束（保持纯逻辑层）
- 不修改 `GameCLI` 的任何代码（除非必要的 bug 修复）
- 不实现 CLI 与 GUI 存档互通
- 不引入 CloudKit 同步（可后续扩展）

### 验收标准

- 每完成一个优先级 P：
  - SwiftPM 侧：执行 `swift build && swift test`，确保 CLI/GameCore 不受影响
  - Xcode 侧：执行 `xcodebuild build -scheme SaluMacApp -destination 'platform=macOS'`，确保 macOS App 可编译
- macOS App 可独立运行，不依赖终端

### 测试命令参考

| 组件 | 命令 | 说明 |
|------|------|------|
| GameCore | `swift test --filter GameCoreTests` | SwiftPM 原生测试 |
| GameCLI | `swift test --filter GameCLITests` | SwiftPM 原生测试 |
| SaluMacApp (编译) | `xcodebuild build -scheme SaluMacApp -destination 'platform=macOS'` | Xcode 编译 |
| SaluMacApp (测试) | `xcodebuild test -scheme SaluMacApp -destination 'platform=macOS'` | Xcode 单元测试 |
| SaluMacApp (UI 测试) | `xcodebuild test -scheme SaluMacAppUITests -destination 'platform=macOS'` | Xcode UI 测试（可选） |

---

## 1. 约束与前置

### 架构约束

```
SaluMacApp (Xcode Project / macOS App)
    │
    ├── 依赖 GameCore (Swift Package)
    │       └── 纯逻辑层（规则/状态/引擎/Definition+Registry/SeededRNG）
    │
    └── App 内部实现
            ├── Models/       → SwiftData 模型
            ├── ViewModels/   → ObservableObject / @Observable
            ├── Views/        → SwiftUI 界面
            └── Services/     → 游戏流程封装
```

### 依赖方向

- `SaluMacApp → GameCore` ✅
- `GameCore → SaluMacApp` ❌ 禁止
- `GameCLI ↔ SaluMacApp` ❌ 无依赖关系

### GameCore 可复用的部分

| 模块 | 复用方式 |
|------|----------|
| `BattleEngine` | 直接使用，传入 `RunState` 转换的战斗参数 |
| `RunState` | 作为内存中的游戏状态，GUI 负责转换到 SwiftData |
| `RunSnapshot` | 可参考其结构设计 SwiftData 模型，但不直接使用 |
| `BattleRecord` | 可参考其结构设计 SwiftData 模型 |
| `CardRegistry` / `EnemyRegistry` / `RelicRegistry` 等 | 直接使用，获取定义与展示信息 |
| `MapGenerator` | 直接使用，生成地图 |
| `RewardGenerator` / `ShopInventory` 等 | 直接使用 |

### GameCore 不可用的部分

| 模块 | 原因 | GUI 替代方案 |
|------|------|--------------|
| `RunSaveStore` 协议 | 仅定义接口，实现在 CLI | SwiftData 直接存储 |
| `BattleHistoryStore` 协议 | 同上 | SwiftData 直接存储 |
| `History.swift` | 使用 Foundation Date/UUID | SwiftData 模型自带时间戳 |

---

## 2. 调研范围（本次 plan 实际查过的文件）

- `Package.swift`
- `Sources/GameCore/AGENTS.md`
- `Sources/GameCLI/AGENTS.md`
- `Sources/GameCore/Run/RunState.swift`
- `Sources/GameCore/Run/RunSnapshot.swift`
- `Sources/GameCore/Battle/BattleState.swift`
- `Sources/GameCore/Battle/BattleEngine.swift`
- `Sources/GameCore/Entity/Entity.swift`
- `Sources/GameCore/Map/MapNode.swift`
- `Sources/GameCore/Cards/Card.swift`
- `Sources/GameCore/Relics/RelicManager.swift`
- `Sources/GameCore/History.swift`
- `Sources/GameCLI/GameCLI.swift`
- `Sources/GameCLI/Persistence/*`
- `.codex/docs/本地存储说明.md`
- `.codex/docs/Salu游戏业务说明（玩法系统与触发规则）.md`

---

## 3. Plan A（按优先级）

### P1（必须）：创建 macOS App Xcode 工程，依赖 GameCore

#### 目标

- 创建一个可运行的空 macOS App，能够导入并使用 `GameCore`
- 验证 `GameCore` 作为 Swift Package 可被 Xcode 项目正确引用

#### 改动点

1. 在仓库根目录创建 `SaluMacApp/` 目录（Xcode 项目）
2. 配置项目：
   - 目标平台：macOS 14.0+（支持 SwiftData）
   - Swift 6.0+
   - 添加本地 Package 依赖指向 `../`（仓库根目录的 `Package.swift`）

#### 实现步骤

1. 使用 Xcode 创建 macOS App 项目（SwiftUI App）
2. 将本地 Salu Swift Package 作为依赖添加到项目
3. 在 App 入口验证导入：
   ```swift
   import GameCore
   
   @main
   struct SaluMacApp: App {
       var body: some Scene {
           WindowGroup {
               ContentView()
           }
       }
   }
   
   struct ContentView: View {
       var body: some View {
           // 验证 GameCore 可用
           let _ = CardRegistry.get(CardID("strike"))
           Text("Salu macOS App")
       }
   }
   ```

#### 测试/验证

- `swift build && swift test`（仓库根目录）通过，CLI/GameCore 不受影响
- `xcodebuild build -scheme SaluMacApp -destination 'platform=macOS'` 成功
- 在 Xcode 中运行 App，能够显示基本界面

#### 风险与回归点

- Xcode 项目与 SwiftPM 共存可能需要调整 `.gitignore`
- 需要确保 GameCore 的 `public` 访问级别正确暴露所需类型

---

### P2（必须）：设计并实现 SwiftData 数据模型

#### 目标

- 使用 SwiftData 实现游戏存档（Run Save）和战斗历史（Battle History）
- 支持基本的 CRUD 操作

#### 数据模型设计

##### RunSave（冒险存档）

```swift
@Model
final class RunSave {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    
    // 基础信息
    var seed: UInt64
    var floor: Int
    var maxFloor: Int
    var gold: Int
    
    // 玩家状态
    var playerMaxHP: Int
    var playerCurrentHP: Int
    var playerStatuses: [String: Int]  // StatusID.rawValue -> stacks
    
    // 牌组（嵌套模型或 JSON）
    var deckData: Data  // JSON encoded [CardData]
    
    // 遗物
    var relicIds: [String]  // RelicID.rawValue array
    
    // 消耗品
    var consumableIds: [String]  // ConsumableID.rawValue array
    
    // 地图（嵌套模型或 JSON）
    var mapData: Data  // JSON encoded [NodeData]
    var currentNodeId: String?
    
    // 状态
    var isOver: Bool
    var won: Bool
}
```

##### BattleHistory（战斗历史）

```swift
@Model
final class BattleHistory {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var seed: UInt64
    
    // 结果
    var won: Bool
    var turnsPlayed: Int
    
    // 玩家状态
    var playerName: String
    var playerMaxHP: Int
    var playerFinalHP: Int
    
    // 敌人（JSON）
    var enemiesData: Data  // JSON encoded [EnemyBattleData]
    
    // 统计
    var cardsPlayed: Int
    var strikesPlayed: Int
    var defendsPlayed: Int
    var totalDamageDealt: Int
    var totalDamageTaken: Int
    var totalBlockGained: Int
}
```

##### Settings（设置）

使用 `@AppStorage` 而非 SwiftData：

```swift
@AppStorage("showBattleLog") var showBattleLog: Bool = true
@AppStorage("soundEnabled") var soundEnabled: Bool = true
// ...
```

#### 实现步骤

1. 创建 `Models/` 目录
2. 实现 `RunSave.swift`
3. 实现 `BattleHistory.swift`
4. 实现辅助的 Codable 结构体（`CardData`、`NodeData`、`EnemyBattleData`）
5. 创建 `DataService.swift` 封装基本的存取操作
6. 在 App 入口配置 ModelContainer

#### 测试/验证

- `swift build && swift test`（仓库根目录）通过
- `xcodebuild build -scheme SaluMacApp -destination 'platform=macOS'` 成功
- 创建一个简单的测试视图，验证可以创建/读取/删除 RunSave
- （可选）`xcodebuild test -scheme SaluMacApp ...` 通过 SwiftData 模型的单元测试

---

### P3（重要）：实现游戏状态管理（ViewModel / 状态机）

#### 目标

- 封装 `RunState` ↔ `RunSave` 的转换逻辑
- 实现游戏流程状态机（主菜单 → 冒险 → 战斗 → 奖励 → ...）
- 为 SwiftUI 视图提供可观察的状态

#### 架构设计

```
GameManager (ObservableObject / @Observable)
    │
    ├── gameState: GameState (enum)
    │       ├── .mainMenu
    │       ├── .adventure(AdventureState)
    │       ├── .battle(BattleState)
    │       ├── .reward(RewardState)
    │       ├── .shop(ShopState)
    │       ├── .event(EventState)
    │       └── .gameOver(GameOverState)
    │
    ├── runState: RunState?
    ├── battleEngine: BattleEngine?
    │
    └── 方法
            ├── startNewRun(seed:)
            ├── continueRun()
            ├── enterNode(_:)
            ├── handleBattleAction(_:)
            └── ...
```

#### 实现步骤

1. 创建 `ViewModels/` 目录
2. 实现 `GameState.swift`（状态枚举）
3. 实现 `GameManager.swift`（核心状态管理器）
4. 实现 `RunSaveConverter.swift`（`RunState` ↔ `RunSave` 转换）
5. 实现 `BattleHistoryConverter.swift`（`BattleRecord` → `BattleHistory`）

#### 测试/验证

- `swift build && swift test`（仓库根目录）通过
- `xcodebuild build -scheme SaluMacApp -destination 'platform=macOS'` 成功
- `xcodebuild test -scheme SaluMacApp -destination 'platform=macOS'` 通过：
  - 单元测试：`RunSaveConverter` 转换正确
  - 单元测试：`GameManager` 状态流转正确

---

### P4（重要）：实现主菜单与冒险地图界面

#### 目标

- 实现主菜单界面（新游戏/继续/设置/退出）
- 实现冒险地图界面（地图可视化、节点选择）

#### 界面设计

##### 主菜单

- 标题 + Logo
- 按钮组：
  - 新游戏（若有存档则显示"继续"和"新游戏"）
  - 设置
  - 退出

##### 冒险地图

- 顶部：玩家状态栏（HP、金币、遗物图标）
- 中间：地图可视化（节点图，可点击选择）
- 底部：牌组/遗物查看按钮

#### 实现步骤

1. 创建 `Views/` 目录结构：
   ```
   Views/
   ├── MainMenuView.swift
   ├── MapView.swift
   ├── Components/
   │   ├── PlayerStatusBar.swift
   │   ├── MapNodeView.swift
   │   └── RelicIconView.swift
   └── ...
   ```
2. 实现主菜单视图
3. 实现地图可视化组件
4. 连接 `GameManager` 实现交互逻辑

#### 测试/验证

- `swift build && swift test`（仓库根目录）通过
- `xcodebuild build -scheme SaluMacApp -destination 'platform=macOS'` 成功
- 手动测试：可以开始新游戏、在地图上选择节点

---

### P5（重要）：实现战斗界面

#### 目标

- 实现完整的战斗界面
- 支持出牌、目标选择、结束回合

#### 界面设计

```
┌─────────────────────────────────────────────────┐
│ 回合数 / 种子 / 遗物                            │
├─────────────────────────────────────────────────┤
│                                                 │
│              敌人区域                            │
│     [敌人1: HP/意图]  [敌人2: HP/意图]          │
│                                                 │
├─────────────────────────────────────────────────┤
│                                                 │
│              玩家区域                            │
│     [HP条]  [格挡]  [能量: ●●●]                 │
│                                                 │
├─────────────────────────────────────────────────┤
│                                                 │
│              手牌区域                            │
│   [卡1] [卡2] [卡3] [卡4] [卡5]                  │
│                                                 │
├─────────────────────────────────────────────────┤
│ 抽牌堆: N  弃牌堆: M      [结束回合]            │
└─────────────────────────────────────────────────┘
```

#### 实现步骤

1. 实现战斗相关视图：
   ```
   Views/
   ├── BattleView.swift
   ├── Components/
   │   ├── EnemyView.swift
   │   ├── PlayerBattleView.swift
   │   ├── HandView.swift
   │   ├── CardView.swift
   │   └── IntentView.swift
   └── ...
   ```
2. 实现卡牌点击 → 目标选择 → 出牌流程
3. 实现战斗事件日志展示（可选）
4. 实现战斗结束后的过渡

#### 测试/验证

- `swift build && swift test`（仓库根目录）通过
- `xcodebuild build -scheme SaluMacApp -destination 'platform=macOS'` 成功
- 手动测试：可以完成一场完整战斗
- 战斗结果正确写入 `BattleHistory`

---

### P6（重要）：实现奖励、商店、事件、休息点界面

#### 目标

- 实现战斗胜利后的奖励选择界面
- 实现商店界面（买卡/买遗物/买消耗品/删牌）
- 实现事件界面（选项选择）
- 实现休息点界面（休息/升级）

#### 实现步骤

1. 实现奖励相关视图：
   - `RewardView.swift`（金币 + 卡牌选择 + 遗物）
2. 实现商店相关视图：
   - `ShopView.swift`
   - `CardPurchaseView.swift`
   - `RelicPurchaseView.swift`
   - `RemoveCardView.swift`
3. 实现事件相关视图：
   - `EventView.swift`
4. 实现休息点相关视图：
   - `RestView.swift`
   - `UpgradeCardView.swift`

#### 测试/验证

- `swift build && swift test`（仓库根目录）通过
- `xcodebuild build -scheme SaluMacApp -destination 'platform=macOS'` 成功
- 手动测试：可以完成一次完整冒险（从主菜单到通关/失败）

---

### P7（优化）：实现历史记录与统计界面

#### 目标

- 实现战斗历史记录列表
- 实现统计数据展示

#### 实现步骤

1. 实现历史相关视图：
   - `HistoryListView.swift`
   - `BattleDetailView.swift`
   - `StatisticsView.swift`
2. 实现设置界面：
   - `SettingsView.swift`

#### 测试/验证

- `swift build && swift test`（仓库根目录）通过
- `xcodebuild build -scheme SaluMacApp -destination 'platform=macOS'` 成功
- 手动测试：可以查看历史记录和统计

---

### P8（优化）：视觉优化与动画

#### 目标

- 添加战斗动画（出牌、伤害、格挡）
- 优化整体视觉风格
- 添加音效（可选）

#### 实现步骤

1. 为战斗事件添加动画
2. 统一颜色主题和字体
3. 添加转场动画

#### 测试/验证

- `swift build && swift test`（仓库根目录）通过
- `xcodebuild build -scheme SaluMacApp -destination 'platform=macOS'` 成功
- 手动验收视觉效果

---

## 4. 执行工作流

### 执行规则

- 按优先级顺序执行（P1 → P2 → ... → P8）
- 每完成一个 P：
  - 仓库根目录执行 `swift build && swift test`，确保 CLI/GameCore 不受影响
  - 执行 `xcodebuild build -scheme SaluMacApp -destination 'platform=macOS'`，确保 macOS App 可编译
- 涉及 macOS App 单元测试时：`xcodebuild test -scheme SaluMacApp -destination 'platform=macOS'`

### 进度记录

每完成一个 P，在下方记录：

| P | 完成日期 | 验证命令 | 结果 |
|---|----------|----------|------|
| P1 | - | - | - |
| P2 | - | - | - |
| P3 | - | - | - |
| P4 | - | - | - |
| P5 | - | - | - |
| P6 | - | - | - |
| P7 | - | - | - |
| P8 | - | - | - |

---

## 5. 文件结构预览

完成后的 macOS App 结构：

```
SaluMacApp/
├── SaluMacApp.xcodeproj
├── SaluMacApp/
│   ├── SaluMacAppApp.swift          # App 入口
│   ├── ContentView.swift            # 根视图（路由）
│   │
│   ├── Models/
│   │   ├── RunSave.swift            # SwiftData: 冒险存档
│   │   ├── BattleHistory.swift      # SwiftData: 战斗历史
│   │   └── DataTypes.swift          # Codable 辅助类型
│   │
│   ├── ViewModels/
│   │   ├── GameState.swift          # 游戏状态枚举
│   │   ├── GameManager.swift        # 核心状态管理器
│   │   ├── RunSaveConverter.swift   # RunState ↔ RunSave
│   │   └── BattleHistoryConverter.swift
│   │
│   ├── Views/
│   │   ├── MainMenuView.swift
│   │   ├── MapView.swift
│   │   ├── BattleView.swift
│   │   ├── RewardView.swift
│   │   ├── ShopView.swift
│   │   ├── EventView.swift
│   │   ├── RestView.swift
│   │   ├── HistoryListView.swift
│   │   ├── StatisticsView.swift
│   │   ├── SettingsView.swift
│   │   └── Components/
│   │       ├── PlayerStatusBar.swift
│   │       ├── MapNodeView.swift
│   │       ├── CardView.swift
│   │       ├── EnemyView.swift
│   │       └── ...
│   │
│   ├── Services/
│   │   └── DataService.swift        # SwiftData 存取封装
│   │
│   └── Resources/
│       └── Assets.xcassets
│
└── SaluMacAppTests/
    └── ...
```

---

## 6. 技术选型说明

### 为什么选择 SwiftData 而非 JSON 文件？

1. **原生集成**：SwiftData 与 SwiftUI 深度集成，`@Query` 等属性包装器使数据绑定更自然
2. **自动迁移**：SwiftData 支持模型版本迁移，比手动管理 JSON 版本更可靠
3. **性能**：对于大量历史记录，数据库查询比全量加载 JSON 更高效
4. **类型安全**：编译时检查，减少运行时错误

### 为什么不共享 CLI 的持久化代码？

1. **技术栈差异**：CLI 使用 Foundation 的 FileManager + JSONEncoder，GUI 使用 SwiftData
2. **存储位置差异**：CLI 使用 Application Support 目录，GUI 使用 SwiftData 默认容器
3. **复杂度**：抽象一套同时支持两种后端的持久化层，增加维护成本

### 为什么 GUI 不依赖 GameCLI？

1. **避免引入无关代码**：GameCLI 包含 ANSI 终端渲染、`readLine()` 输入等 GUI 不需要的代码
2. **解耦**：修改 GameCLI 不会影响 GUI，反之亦然
3. **清晰的模块边界**：GameCore（逻辑）+ GUI（展示）的两层架构更清晰
