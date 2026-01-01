# Salu MVP 开发计划 - Plan A

## 项目现状分析

| 组件 | 当前状态 | 待完成 |
|------|---------|--------|
| Package.swift | 只有 GameCLI 目标 | 需添加 GameCore 库 |
| GameCore/ | 空目录 | 需实现全部核心逻辑 |
| GameCLI/ | Hello World 占位 | 需实现完整 CLI 交互 |

---

## 优先级划分

### P1 - 基础数据模型与 Package 配置
**目标**：建立项目骨架，能够编译通过

- [ ] 1.1 更新 `Package.swift`，添加 GameCore 库目标
- [ ] 1.2 创建 `GameCore/Models.swift`：定义核心数据类型
  - `CardKind` 枚举（strike / defend）
  - `Card` 结构体（id, kind, cost）
  - `Entity` 结构体（玩家/敌人的 HP, Block）
  - `BattleState` 结构体（牌堆/手牌/弃牌堆/能量/回合数）
- [ ] 1.3 创建 `GameCore/RNG.swift`：可复现的随机数生成器
  - 支持固定 seed
  - 提供 shuffle 方法

**验收**：`swift build` 编译成功

---

### P2 - 事件系统
**目标**：定义战斗事件，为日志和测试提供基础

- [ ] 2.1 创建 `GameCore/Events.swift`：定义 `BattleEvent` 枚举
  - `turnStarted(turn: Int)`
  - `drew(cardId: String)`
  - `played(cardId: String)`
  - `damageDealt(source: String, target: String, amount: Int, blocked: Int)`
  - `blockGained(target: String, amount: Int)`
  - `shuffled`
  - `enemyAction(action: String, damage: Int)`
  - `turnEnded(turn: Int)`
  - `battleWon`
  - `battleLost`

**验收**：`swift build` 编译成功

---

### P3 - 战斗引擎核心
**目标**：实现战斗逻辑的核心计算

- [ ] 3.1 创建 `GameCore/Actions.swift`：定义玩家动作
  - `PlayerAction` 枚举（playCard / endTurn）
- [ ] 3.2 创建 `GameCore/BattleEngine.swift`：战斗引擎
  - 初始化战斗（创建初始牌组、洗牌）
  - 回合开始处理（重置能量、清除玩家格挡、抽牌）
  - 出牌处理（消耗能量、执行卡牌效果）
  - 伤害结算（先扣格挡再扣血）
  - 回合结束处理（弃手牌、敌人行动）
  - 判断胜负

**验收**：`swift build` 编译成功

---

### P4 - CLI 交互实现
**目标**：实现命令行用户界面

- [ ] 4.1 更新 `GameCLI/GameCLI.swift`：完整 CLI 实现
  - 解析命令行参数（--seed）
  - 打印战斗状态（HP/Block/能量/手牌）
  - 读取用户输入（1-n 出牌 / 0 结束回合 / q 退出）
  - 调用 BattleEngine 处理动作
  - 打印事件日志
  - 游戏主循环

**验收**：`swift build` 编译成功，可运行

---

### P5 - 集成测试与调试
**目标**：确保游戏可完整运行一局

- [ ] 5.1 运行 `swift run GameCLI --seed 1` 进行测试
- [ ] 5.2 验证同一 seed + 同样输入 = 相同结果
- [ ] 5.3 验证抽牌堆耗尽时正确洗回弃牌堆
- [ ] 5.4 验证伤害与格挡结算正确
- [ ] 5.5 修复发现的任何 bug

**验收**：能完整跑完一局（胜或负）

---

## 详细设计

### 数据模型设计

```swift
// CardKind
enum CardKind: String {
    case strike
    case defend
}

// Card
struct Card: Identifiable {
    let id: String
    let kind: CardKind
    var cost: Int { kind == .strike ? 1 : 1 }
    var damage: Int { kind == .strike ? 6 : 0 }
    var block: Int { kind == .defend ? 5 : 0 }
}

// Entity
struct Entity {
    let id: String
    let name: String
    var maxHP: Int
    var currentHP: Int
    var block: Int
}

// BattleState
struct BattleState {
    var player: Entity
    var enemy: Entity
    var energy: Int
    var maxEnergy: Int
    var turn: Int
    var drawPile: [Card]
    var hand: [Card]
    var discardPile: [Card]
    var isPlayerTurn: Bool
    var isOver: Bool
    var playerWon: Bool?
}
```

### RNG 设计

```swift
// 使用线性同余生成器 (LCG) 实现可复现随机
final class SeededRNG {
    private var state: UInt64
    
    init(seed: UInt64) {
        self.state = seed
    }
    
    func next() -> UInt64 { ... }
    func nextInt(upperBound: Int) -> Int { ... }
    func shuffle<T>(_ array: inout [T]) { ... }
}
```

### 战斗流程

```
游戏开始
  └─ 初始化牌组（5x Strike + 5x Defend）
  └─ 洗牌
  └─ 进入第 1 回合

回合开始
  ├─ 能量重置为 3
  ├─ 玩家格挡清零
  └─ 抽 5 张牌

玩家阶段（循环）
  ├─ 显示状态
  ├─ 等待输入
  ├─ 处理动作
  │   ├─ 出牌：消耗能量，执行效果
  │   └─ 结束回合：进入敌人阶段
  └─ 检查胜负

敌人阶段
  ├─ 敌人格挡清零（下回合开始时）
  ├─ 执行攻击（固定 7 伤害）
  └─ 检查胜负

回合结束
  ├─ 手牌全部弃掉
  └─ 进入下一回合
```

---

## 文件结构

```
salu/
├── Package.swift                 # P1 更新
├── .cursor/plans/
│   └── plan-a-mvp.md            # 本计划
├── Sources/
│   ├── GameCore/
│   │   ├── Models.swift         # P1
│   │   ├── RNG.swift            # P1
│   │   ├── Events.swift         # P2
│   │   ├── Actions.swift        # P3
│   │   └── BattleEngine.swift   # P3
│   └── GameCLI/
│       └── GameCLI.swift        # P4 更新
```

---

## 时间估算

| 优先级 | 预计时间 | 累计 |
|--------|---------|------|
| P1 | 15 分钟 | 15 分钟 |
| P2 | 5 分钟 | 20 分钟 |
| P3 | 20 分钟 | 40 分钟 |
| P4 | 15 分钟 | 55 分钟 |
| P5 | 10 分钟 | 65 分钟 |

---

## 开始执行

确认计划后，将按 P1 → P2 → P3 → P4 → P5 顺序执行。每完成一个优先级后进行 `swift build` 验证。

