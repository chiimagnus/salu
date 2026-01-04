# Salu 协议驱动开发重构计划 (Plan A)

> 创建时间：2026-01-03
> 状态：进行中 (P1~P6 ✅ 完成, P7 进行中)
> **最后更新：2026-01-04 - P1~P6 已完成并通过所有测试**

---

## 📋 概述

本计划将 Salu 项目从**枚举+Switch**模式重构为**协议驱动开发（Protocol-Oriented Programming）**模式，以支持更灵活的扩展性，便于添加更多卡牌和敌人。

### 文档关系：`architecture-design.md` 要不要合并？

- **`protocol-driven-design-plan.md`（本文）**：协议驱动重构的**实施主文档**（按 P1~P7 执行、可直接落代码）
- **`architecture-design.md`**：产品/系统的**宏观架构与功能愿景**（偏“是什么”）

建议做法（默认）：
- **不全文合并**，只做 **互相引用 + 对齐关键结论**，避免出现两套冲突的路线图编号
- 如果你更想要“单文档单真相”，我也可以把 `architecture-design.md` 的“目标架构/模块拆分/关键决策”提炼进本文的附录，并在 `architecture-design.md` 里改成只保留链接

---

## 🎯 总体目标：把“整个项目”重构为协议驱动（破坏性）

### 我们到底要“协议化”什么？

本项目里“最需要协议驱动”的并不是所有东西都变成 protocol，而是把**需要扩展的内容域**（Content Domain）从“枚举 + switch + 硬编码”重构为：

- **Definition（定义）**：不可变、可注册、可枚举的“内容定义”（卡牌/敌人/状态/遗物/房间/屏幕等）
- **Instance（实例）**：运行时对象（某一张卡的实例、某一只敌人的实例、某一场战斗、一次冒险 Run）
- **Registry（注册表）**：把 `ID → Definition` 的查找集中化，消除全项目的 `switch` 分支扩展点
- **System / Hook（系统插件/钩子）**：用统一的触发点把“卡牌效果/状态效果/敌人行动/遗物效果/房间效果”接入引擎

### 破坏性重构原则（Hard Breaking，不打补丁）

- **不保留旧接口做兼容层**：不做 “fallback 到旧 switch” 的桥接
- **一次性删除旧枚举扩展点**：如 `CardKind`、`EnemyKind`、`EnemyData.get()`、`EnemyBehaviors` 等（按阶段删除，但每阶段都是“彻底替换”）
- **所有可扩展域都通过 `ID + Definition + Registry` 扩展**：新增内容只新增文件 + 注册，不修改核心引擎 switch
- **GameCore 保持纯逻辑**：不引入 `Foundation`（History.swift 例外），不 `print`/不读 stdin

### 统一框架层（必须先落地，否则 P1~P6 会彼此打架）

> 这部分是本 plan 的“框架基座”。后续 P1/P2/P3/P4/P5/P6 都必须复用这套基座，而不是各自定义一套 Result 枚举。

#### 1) 强类型 ID（消除字符串散落 & 拼写错误）

- `CardID`
- `EnemyID`
- `StatusID`
- `RelicID`
- `RoomID`
- `ScreenID`

要求：
- 都是 `struct`（`rawValue: String`），`Hashable & Sendable`
- 只允许在 Registry 的“注册入口”使用裸字符串

#### 2) 统一效果管线：`BattleEffect` / `RunEffect`（核心）

- **BattleEffect**：战斗内的所有“可执行效果”统一用一套枚举/指令描述（伤害、格挡、抽牌、施加状态、改能量、生成事件等）
- **RunEffect**：冒险层的效果（加卡、加遗物、加金币、回血、进入房间、结算战斗奖励等）

要求：
- “定义层”只产出 `Effect` 描述，不直接改 `BattleState/RunState`
- 只有 Engine（BattleEngine/RunEngine）能执行效果并发出事件

#### 3) 统一触发点：`BattleTrigger` / `RunTrigger`

所有“被动系统”（状态、遗物、一些敌人被动）通过 trigger 接入：

- `onBattleStart / onTurnStart / onCardPlayed / onDamageDealt / onBattleEnd ...`
- Hook 的返回值同样是 `BattleEffect`（由引擎执行）

#### 4) 分层与依赖方向（最重要的框架约束）

```
GameCLI（表现层）
  ├─ Screens / Renderer / IO
  └─ 只依赖 GameCore（协议 + 引擎公开接口）

GameCore（逻辑层）
  ├─ Kernel（框架基座）: IDs / Registries / Effects / Hooks
  ├─ Engine（引擎）: BattleEngine / RunEngine（只认识协议，不认识具体内容）
  └─ Content（内容实现）: Cards/Enemies/Status/Relics/Rooms 的具体 Definition（可替换、可扩展）
```

---

## 🔍 当前架构分析

### 已使用协议驱动的模块 ✅

| 模块 | 协议 | 实现 |
|------|------|------|
| 敌人 AI | `EnemyAI` | `JawWormAI`, `CultistAI`, `LouseAI`, `SlimeAI` |

### 仍使用枚举+Switch的模块 ⚠️

| 模块 | 当前实现 | 问题 |
|------|----------|------|
| **卡牌系统** | `CardKind` 枚举 + `Card.cost/damage/block` 的 switch | 添加新卡需修改多处 switch |
| **卡牌效果** | `BattleEngine.executeCardEffect()` 的 switch | 所有效果耦合在一个巨大的 switch 中 |
| **敌人数据** | `EnemyData.get()` 的 switch | 添加新敌人需修改 switch |
| **敌人种类** | `EnemyKind` 枚举 | 新敌人需修改枚举定义 |
| **状态效果** | 硬编码在 `Entity` 中 | 无法轻松添加新状态 |
| **房间类型** | `RoomType` 枚举 | 当前已足够，**无需协议化** |

### 应保持枚举的模块 ✓

| 模块 | 原因 |
|------|------|
| `BattleEvent` | 事件类型有限且稳定，枚举更适合模式匹配 |
| `PlayerAction` | 玩家动作类型有限且稳定 |
| `BattleTrigger` | 战斗触发点有限且清晰，枚举更适合模式匹配 |
| `RoomType` | 房间类型相对固定，枚举更简洁 |

---

## 🎯 重构优先级（修订版）

```
┌────────────────────────────────────────────────────────────────┐
│  P1: 卡牌系统协议化                    ⭐⭐⭐ 最重要           │
│  ├── CardID/StatusID 强类型（Kernel/IDs.swift）                │
│  ├── BattleEffect 统一效果（Kernel/BattleEffect.swift）        │
│  ├── CardDefinition（play → [BattleEffect]）                   │
│  ├── Card（实例：id + cardId）                                 │
│  ├── CardRegistry（唯一扩展点：新增卡牌只需注册）              │
│  └── 卡牌升级：upgradedId（升级版也是一个 CardID 定义）        │
├────────────────────────────────────────────────────────────────┤
│  P2: 状态效果系统协议化                ⭐⭐ 重要               │
│  ├── StatusDefinition 协议（修正 + 触发）                      │
│  ├── StatusID（强类型） + StatusRegistry                       │
│  ├── StatusContainer 纯数据容器（Entity 仅持有 statuses）       │
│  ├── 易伤/虚弱/力量/敏捷/中毒 实现                             │
│  └── 与 BattleEngine 伤害计算集成                              │
├────────────────────────────────────────────────────────────────┤
│  P3: 敌人系统统一                      ⭐⭐ 重要               │
│  ├── EnemyID（强类型） + EnemyRegistry                          │
│  ├── EnemyDefinition（chooseMove → EnemyMove）                  │
│  ├── EnemyMove（intent + effects）                              │
│  ├── 迁移现有 5 种敌人                                         │
│  └── 添加 2 个新敌人验证                                       │
├────────────────────────────────────────────────────────────────┤
│  P4: 遗物系统设计                      ⭐ 一般                 │
│  ├── RelicID（强类型） + RelicRegistry                           │
│  ├── BattleTrigger（战斗触发点） → [BattleEffect]                │
│  ├── RelicManager（汇总效果，由 BattleEngine 执行）              │
│  └── 3 个基础遗物实现                                          │
├────────────────────────────────────────────────────────────────┤
│  P5: Run/房间/地图流程协议化           ⭐⭐ 重要               │
│  ├── RoomType 保留 enum，但用 Registry/Handler 消灭 CLI switch   │
│  ├── RunSeedStrategy（统一 battleSeed/bossSeed 派生）            │
│  └── MapGenerating（地图生成策略协议，Act/难度可扩展）            │
├────────────────────────────────────────────────────────────────┤
│  P6: 持久化与 I/O 协议化              ⭐⭐ 重要               │
│  ├── HistoryStore / RunSaveStore 协议（GameCore 定义）           │
│  ├── File/JSON 实现放在 GameCLI（唯一 I/O 层）                    │
│  └── Screen/Router 协议化，统一输入输出依赖注入                   │
├────────────────────────────────────────────────────────────────┤
│  P7: Run 存档系统（Save/Load）         ⭐⭐ 重要               │
│  ├── RunSnapshot（Codable）+ RunSaveStore 具体实现               │
│  └── CLI 支持继续冒险/存档管理（不引入新 I/O 到 GameCore）        │
└────────────────────────────────────────────────────────────────┘

已移除：
- P4(旧): 房间系统协议化 → RoomType 枚举已足够，无需过度设计
```

---

## ⚠️ 框架级约束（P1 ~ P7 都必须遵守）

### 约束 1：效果统一（BattleEffect / RunEffect）

- **battle 内**：卡牌/敌人/状态/遗物只允许产出 `[BattleEffect]`
- **执行边界**：只有 `BattleEngine.apply(effect:)` 能修改 `BattleState` 并 `emit(BattleEvent)`
- **run 内**：地图/房间/奖励/存档只允许产出 `[RunEffect]`（由 `RunEngine` 执行并 `emit(RunEvent)`，在 P5/P6 建立）

```swift
public enum BattleEffect: Sendable, Equatable {
    case dealDamage(target: EffectTarget, base: Int)
    case gainBlock(target: EffectTarget, base: Int)
    case applyStatus(target: EffectTarget, statusId: StatusID, stacks: Int)
    case heal(target: EffectTarget, amount: Int)
}
```

### 约束 2：强类型 ID（禁止散落字符串）

- `CardID/StatusID/EnemyID/RelicID` 必须强类型（并 `ExpressibleByStringLiteral`）
- `BattleEvent`/`RunEvent` 的载荷存 **ID**，不存 UI 文本；渲染时通过 Registry 取 `name/icon/rulesText`

### 约束 3：容器只管数据（不 tick / 不 emit / 不 apply）

- `StatusContainer`：只存 `StatusID -> stacks`，递减/触发由引擎在 turn hook 里做
- `RelicManager`：只汇总 `RelicDefinition.onBattleTrigger(...)` 产生的 effects，执行仍由 BattleEngine 负责

### 约束 4：可复现性（禁止 UUID/Foundation）

- 所有随机必须来自注入的 `SeededRNG`
- 敌人必须 **先 plan 后 execute**：plan 阶段用 rng，并把随机结果固化到 `EnemyMove.effects`
- GameCore 禁止 `UUID()` / `Date()` / `Foundation`（`History.swift` 例外）

### 关键迁移策略：删除 CardKind（P1 破坏性）

```
迁移策略：
1. **P1 直接删除 `CardKind` / 旧 `Card` 的 switch 计算属性**（破坏性）
2. `Card`（实例）仅保留 `CardID`（cardId）与 instanceId
3. 所有出牌/展示/统计都从 `CardRegistry` 查定义（无 fallback）
```

---

## P1: 卡牌系统协议化 ⭐⭐⭐ ✅ **已完成**

> **实施日期**: 2026-01-03  
> **状态**: ✅ 完成并通过所有测试  
> **Commits**: 81729bd, a842589, 174042a

### 这次重写 P1 的原因（来自代码库真实依赖）

我已核对当前实现：

- `Sources/GameCore/Cards/Card.swift`：几乎所有卡牌信息来自 `switch card.kind`（cost/damage/block/draw/status…）
- `Sources/GameCore/Battle/BattleEngine.swift`：`executeCardEffect` 是一个按 `card.kind` 的大 switch
- `Sources/GameCLI/Screens/BattleScreen.swift`：`buildHandArea` 同样按 `card.kind` switch 拼效果文本
- `Sources/GameCLI/Components/EventFormatter.swift`：显示 `.drew/.played` 事件携带的 `cardName`

结论：P1 必须同时解决 **Card 模型 / BattleEngine 执行 / CLI UI 展示** 的扩展点，否则只协议化“卡牌定义”会变成假重构。

### P1 目标（破坏性：不保留兼容层）

- **彻底删除** `CardKind` 以及所有 “按 kind switch” 的扩展点（Card/BattleEngine/BattleScreen）
- 建立 **CardID / CardDefinition / CardRegistry / BattleEffect** 的卡牌框架
- 新增卡牌只做两件事：**新增一个 `CardDefinition` 类型 + 注册到 `CardRegistry`**
- 卡牌升级是框架的一部分：升级版同样是 `CardDefinition`

### P1 新架构设计（以框架为中心）

```
Sources/GameCore/
├── Kernel/                         # 框架基座（Effects/IDs/Targets）
│   ├── IDs.swift                   # CardID/StatusID/...（强类型）
│   └── BattleEffect.swift          # 统一战斗效果（卡/状态/遗物/敌人都用）
│
├── Cards/
│   ├── Card.swift                  # 卡牌实例（只持有 CardID，不再持有 kind）
│   ├── CardDefinition.swift        # 卡牌定义协议
│   ├── CardRegistry.swift          # 注册表
│   ├── StarterDeck.swift           # 起始牌组（改用 CardID）
│   └── Definitions/
│       └── Ironclad/
│           ├── Basic.swift         # Strike/Defend/Bash (+版本)
│           └── Common.swift        # PommelStrike/ShrugItOff/Inflame/Clothesline
│
└── Battle/
    └── BattleEngine.swift          # 破坏性重构：执行 BattleEffect（无卡牌 switch）
```

> 注意：这里不再保留 `CardEffectResult`。卡牌效果直接产出框架基座 `BattleEffect`，这样 P2/P3/P4 都可以复用同一条执行管线。

---

### 关键框架：CardID / BattleEffect / CardDefinition / Card（保留最小代码示例）

#### 1) `CardID`（强类型，禁止散落字符串）

```swift
// Kernel/IDs.swift
public struct CardID: Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.rawValue = value }
}

// P1 先放在 Kernel（P2 会完整化状态系统）
public struct StatusID: Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.rawValue = value }
}
```

#### 2) `BattleEffect`（统一效果枚举：卡牌/状态/遗物/敌人都用）

```swift
// Kernel/BattleEffect.swift
public enum BattleEffect: Sendable, Equatable {
    case dealDamage(target: EffectTarget, base: Int)
    case gainBlock(target: EffectTarget, base: Int)
    case drawCards(count: Int)
    case gainEnergy(amount: Int)
    case applyStatus(target: EffectTarget, statusId: StatusID, stacks: Int)
    case heal(target: EffectTarget, amount: Int)   // P4 遗物等需要
    // 未来扩展：exhaust/addTempCard/shuffleIntoDraw/multiTarget...
}

public enum EffectTarget: Sendable, Equatable {
    case player
    case enemy
}
```

> 为什么要统一：因为目前 `BattleEngine.executeCardEffect`、敌人 debuff、未来遗物/状态都会产生同类“效果”，统一后引擎只有一条执行路径。

#### 3) `CardDefinition`（定义只产出效果，不直接改状态、不直接 emit 事件）

```swift
// Cards/CardDefinition.swift
public protocol CardDefinition: Sendable {
    static var id: CardID { get }
    static var name: String { get }        // 用于 UI（建议中文）
    static var type: CardType { get }
    static var rarity: CardRarity { get }
    static var cost: Int { get }
    static var rulesText: String { get }   // UI 展示文本（替代 BattleScreen 的 switch）

    // 升级（升级版也是另一个 CardID）
    static var upgradedId: CardID? { get }

    // 纯决策：输入是快照，输出是效果
    static func play(snapshot: BattleSnapshot) -> [BattleEffect]
}

public struct BattleSnapshot: Sendable {
    public let turn: Int
    public let player: Entity
    public let enemy: Entity
    public let energy: Int
}
```

#### 4) `Card`（运行时实例：只引用定义）

```swift
// Cards/Card.swift
public struct Card: Identifiable, Sendable, Equatable {
    public let id: String          // instanceId（例如 "strike_1"；由引擎/牌组生成器负责）
    public let cardId: CardID      // cardId（引用卡牌定义）
}
```

---

### 1) CardRegistry（新增卡牌的唯一扩展点）

```swift
// Cards/CardRegistry.swift
public enum CardRegistry {
    private static let defs: [CardID: any CardDefinition.Type] = [
        "strike": Strike.self,
        // ...
    ]

    public static func get(_ id: CardID) -> (any CardDefinition.Type)? { defs[id] }
    public static func require(_ id: CardID) -> any CardDefinition.Type { defs[id]! }
}
```

> 约束：任何地方不允许通过 switch/cardId 字符串去“猜”卡牌行为；必须从 registry resolve。

---

### 2) 与 BattleEngine 的边界（效果管线）

> 这是 P1 的核心：**卡牌定义只产出 BattleEffect；BattleEngine 执行 BattleEffect 并产出 BattleEvent**。

```swift
// Battle/BattleEngine.swift（伪代码骨架，表达边界）
private func executeCard(_ card: Card) {
    let def = CardRegistry.require(card.cardId)

    // 1) 校验 cost
    // 2) 扣能量
    // 3) emit(.played(cardId: card.cardId, cost: def.cost))

    let snapshot = BattleSnapshot(
        turn: state.turn,
        player: state.player,
        enemy: state.enemy,
        energy: state.energy
    )
    let effects = def.play(snapshot: snapshot)
    for e in effects { apply(e) }
}

private func apply(_ effect: BattleEffect) {
    switch effect {
    case .dealDamage(let target, let base):
        // 使用 DamageCalculator（后续 P2 会从状态系统统一修正）
        // applyDamage + emit(.damageDealt...)
        break
    case .gainBlock:
        break
    // ...
    }
}
```

### 3) UI 展示如何去掉 switch（对齐 `BattleScreen.buildHandArea`）

P1 要求把 `BattleScreen.buildHandArea` 中这段：
- `switch card.kind { ... }`

替换为：
- `let def = CardRegistry.require(card.cardId)`
- 展示 `def.name / def.cost / def.rulesText`

这样新增卡牌不会再迫使 UI 改 switch。

---

### P1 破坏性改动清单（必须一次完成）

- **删除**：`Sources/GameCore/Cards/CardKind.swift`
- **重写**：`Sources/GameCore/Cards/Card.swift`（移除 kind/switch，改为 `CardID` 引用定义）
- **重写**：`createStarterDeck()`（改为创建 `Card(cardId: ...)` 的实例）
- **重写**：`BattleEngine.executeCardEffect`（移除按卡牌 switch，改为执行 `BattleEffect`）
- **重写**：`BattleScreen.buildHandArea`（移除按卡牌 switch，改为从 registry 取 `rulesText`）
- **调整事件载荷**（必须，破坏性）：`BattleEvent.played/drew` **改为携带 `CardID`（稳定 ID）而不是 `cardName`（显示字符串）**
  - 直观例子：如果事件里存 `"Strike"`，你以后把显示名改成“打击”，所有事件/测试都要跟着改
  - 如果事件里存 `CardID("strike")`，显示名怎么变都无所谓：CLI 用 `CardRegistry.require(cardId).name` 渲染即可

### P1 实施步骤（高优先级顺序）

- P1.1 建 `Kernel/IDs.swift`：`CardID`（以及后续会用到的 `StatusID`）
- P1.2 建 `Kernel/BattleEffect.swift`：统一效果枚举 + `EffectTarget`
- P1.3 重写 `Card.swift`（实例）为 `id + cardId`
- P1.4 建 `CardDefinition.swift` + `CardRegistry.swift`
- P1.5 用 Definition 重写现有 7 张卡牌（含 Strike+/Defend+/Bash+）
- P1.6 BattleEngine：出牌改为 resolve definition → effects → apply(effect)
- P1.7 BattleScreen：去掉 card.kind switch，展示 rulesText
- P1.8 验证：build + 测试脚本

### P1 验收标准（必须全部通过）

- [ ] 代码库中不存在 `CardKind`（文件删除 + 无引用）
- [ ] `BattleEngine` 不再含 “按卡牌 switch 执行效果”
- [ ] `BattleScreen.buildHandArea` 不再含 “按卡牌 switch 拼描述”
- [ ] 新增卡牌无需修改 BattleEngine/BattleScreen，只需新增 Definition + 注册
- [ ] `swift build` 成功
- [ ] `./.cursor/Scripts/test_game.sh` 成功

---

## P2: 状态效果系统协议化 ⭐⭐ ✅ **已完成**

> **实施日期**: 2026-01-03  
> **状态**: ✅ 完成并通过所有测试  
> **Commits**: bbb674a, 4ff3e17

### P2 重新审查：当前实现的问题（来自真实代码）

我已核对当前实现：

- `Sources/GameCore/Entity/Entity.swift`：状态是 3 个硬编码字段 `vulnerable/weak/strength`，且 `tickStatusEffects()` 直接做递减并返回中文字符串
- `Sources/GameCore/Battle/BattleEngine.swift`：伤害计算直接读 `attacker.strength / attacker.weak / defender.vulnerable`
- `Sources/GameCLI/Screens/BattleScreen.swift`：状态展示写死了 `易伤/虚弱/力量`

结论：如果不把“状态”变成 Definition/Registry/Container 的框架域，未来加 `中毒/敏捷/脆弱` 会再次回到“加字段 + 加 switch”的老路。

### P2 目标（破坏性：不保留兼容字段/兼容属性）

- **删除** `Entity` 中的硬编码状态字段：`vulnerable/weak/strength`
- **删除** `Entity.tickStatusEffects()`（状态递减不属于 Entity；属于战斗系统的 turn hook）
- 建立 **StatusID / StatusDefinition / StatusRegistry / StatusContainer** 的状态框架
- 状态系统必须同时支持两类能力：
  - **修正型**：影响伤害/格挡（易伤/虚弱/力量/敏捷/脆弱）
  - **触发型**：在特定时机产出 `BattleEffect`（如中毒在回合结束造成伤害）
- **所有状态相关输出统一产出 `BattleEffect`**，由 BattleEngine 执行并 emit `BattleEvent`

### P2 新架构设计（以框架为中心）

```
Sources/GameCore/
├── Kernel/
│   └── IDs.swift                  # StatusID（P1 已引入）
│
├── Status/
│   ├── StatusDefinition.swift     # 状态定义协议（纯决策/纯修正）
│   ├── StatusRegistry.swift       # 注册表：StatusID -> Definition
│   ├── StatusContainer.swift      # 纯数据：StatusID -> stacks
│   └── Definitions/
│       ├── Debuffs.swift          # 易伤/虚弱/脆弱/中毒
│       └── Buffs.swift            # 力量/敏捷
│
└── Entity/
    └── Entity.swift               # 破坏性重写：只有 `statuses: StatusContainer`
```

---

### 核心框架（保留最小代码示例）

#### 1) `StatusDefinition`（定义：修正 + 触发）

```swift
// Status/StatusDefinition.swift
public protocol StatusDefinition: Sendable {
    static var id: StatusID { get }
    static var name: String { get }     // UI 展示名（中文）
    static var icon: String { get }
    static var isPositive: Bool { get }

    // 递减规则（用来替代 Entity.tickStatusEffects）
    static var decay: StatusDecay { get }

    // ── 修正型（默认不修正） ───────────────────────────────
    static var outgoingDamagePhase: ModifierPhase? { get }   // nil = 不参与
    static var incomingDamagePhase: ModifierPhase? { get }
    static var blockPhase: ModifierPhase? { get }
    static var priority: Int { get }                         // 保证确定性顺序

    static func modifyOutgoingDamage(_ value: Int, stacks: Int) -> Int
    static func modifyIncomingDamage(_ value: Int, stacks: Int) -> Int
    static func modifyBlock(_ value: Int, stacks: Int) -> Int

    // ── 触发型：产出 BattleEffect（不直接 emit 事件） ───────
    static func onTurnEnd(owner: EffectTarget, stacks: Int, snapshot: BattleSnapshot) -> [BattleEffect]
}

public enum ModifierPhase: Int, Sendable {
    case add = 0        // 先加（如力量/敏捷）
    case multiply = 1   // 再乘（如虚弱/易伤/脆弱）
}

public enum StatusDecay: Sendable {
    case none
    case turnEnd(decreaseBy: Int)  // 常见：每回合 -1
}

extension StatusDefinition {
    public static var outgoingDamagePhase: ModifierPhase? { nil }
    public static var incomingDamagePhase: ModifierPhase? { nil }
    public static var blockPhase: ModifierPhase? { nil }
    public static var priority: Int { 0 }

    public static func modifyOutgoingDamage(_ value: Int, stacks: Int) -> Int { value }
    public static func modifyIncomingDamage(_ value: Int, stacks: Int) -> Int { value }
    public static func modifyBlock(_ value: Int, stacks: Int) -> Int { value }

    public static func onTurnEnd(owner: EffectTarget, stacks: Int, snapshot: BattleSnapshot) -> [BattleEffect] { [] }
}
```

> 关键点：**必须有 priority/phase**，否则遍历 Dictionary 会导致修正顺序不确定（尤其乘法+向下取整时，顺序会改变结果）。

#### 2) `StatusContainer`（纯数据，不产生事件/效果）

```swift
// Status/StatusContainer.swift
public struct StatusContainer: Sendable, Equatable {
    private var stacksById: [StatusID: Int] = [:]

    public init() {}

    public func stacks(of id: StatusID) -> Int { stacksById[id] ?? 0 }

    public mutating func apply(_ id: StatusID, stacks: Int) {
        guard stacks != 0 else { return }
        let newValue = (stacksById[id] ?? 0) + stacks
        if newValue <= 0 { stacksById.removeValue(forKey: id) }
        else { stacksById[id] = newValue }
    }

    public var all: [(id: StatusID, stacks: Int)] {
        stacksById.map { ($0.key, $0.value) }.sorted { $0.id.rawValue < $1.id.rawValue }
    }
}
```

#### 3) `StatusRegistry`（扩展点：新增状态只新增 Definition + 注册）

```swift
// Status/StatusRegistry.swift
public enum StatusRegistry {
    private static let defs: [StatusID: any StatusDefinition.Type] = [
        "vulnerable": Vulnerable.self,
        "weak": Weak.self,
        "strength": Strength.self,
        // ...
    ]
    public static func get(_ id: StatusID) -> (any StatusDefinition.Type)? { defs[id] }
    public static func require(_ id: StatusID) -> any StatusDefinition.Type { defs[id]! }
}
```

---

### P2 与 BattleEngine 的边界（状态不发事件，只发 BattleEffect）

- `BattleEngine` 在 **turnEnd(actor:)** 阶段：
  1) 读取该 actor 的 `statuses`
  2) 对每个状态调用 `StatusDefinition.onTurnEnd(...)` 收集效果
  3) 执行这些 `BattleEffect`（统一走 `apply(effect:)`）
  4) 按 `StatusDefinition.decay` 递减 stacks，并由引擎 emit `.statusExpired`

同时：
- `DamageCalculator` / `BlockCalculator`（可以还是 DamageCalculator）应当：
  - 从 `attacker.statuses` / `defender.statuses` 找到参与修正的定义
  - 按 `phase + priority` 排序后再应用，保证结果稳定

### UI 变更（对齐真实代码）

P2 必须同步修改：
- `BattleScreen.buildStatusLine`：不再写死 `易伤/虚弱/力量`，改为遍历 `entity.statuses.all`，用 `StatusRegistry.require(id).icon/name` 渲染

---

### P2 破坏性改动清单

- **删除**：`Entity.vulnerable/weak/strength` 字段
- **删除**：`Entity.tickStatusEffects()`
- **新增**：`StatusContainer` 并嵌入 `Entity`
- **重构**：`BattleEngine.calculateDamage` 与状态递减时机（改为 turn hook）
- **重构**：`BattleScreen.buildStatusLine`

### P2 实施步骤

- P2.1 新建 `StatusDefinition/StatusRegistry/StatusContainer`
- P2.2 破坏性重写 `Entity`：加入 `statuses: StatusContainer`
- P2.3 实现 5 个状态定义：`Vulnerable/Weak/Strength/Dexterity/Poison`
- P2.4 重构 `DamageCalculator`：按 phase+priority 应用修正（保证确定性）
- P2.5 BattleEngine：加入 `turnEnd(actor:)` 钩子，处理 poison 触发 + 递减
- P2.6 UI：状态行改为 registry 驱动渲染
- P2.7 验证：build + 测试脚本

### P2 验收标准（必须全部通过）

- [x] ✅ `Entity` 不再含 `vulnerable/weak/strength` 字段，也没有 `tickStatusEffects()`
- [x] ✅ `StatusContainer` 不产生 `BattleEvent`（只存数据）
- [x] ✅ `DamageCalculator` 的状态修正顺序确定（phase+priority）
- [x] ✅ 易伤/虚弱/力量/敏捷/中毒 全部可通过注册表扩展
- [x] ✅ `BattleScreen` 状态展示由 registry 驱动（无硬编码 if 链）
- [x] ✅ `swift build` 成功
- [x] ✅ `./.cursor/Scripts/test_game.sh` 成功

### P2 实施总结 ✅

**完成内容**:
- ✅ 创建 `StatusDefinition.swift` (协议 + ModifierPhase + StatusDecay)
- ✅ 创建 `StatusContainer.swift` (纯数据结构)
- ✅ 创建 `StatusRegistry.swift` (注册表)
- ✅ 实现 6 个状态定义 (Vulnerable, Weak, Frail, Poison, Strength, Dexterity)
- ✅ 重构 `Entity` (移除硬编码字段，使用 StatusContainer)
- ✅ 删除 `Entity.tickStatusEffects()`
- ✅ 重构 `calculateDamage` (phase+priority 确定性排序)
- ✅ 重构 `applyBlock` (状态修正)
- ✅ 添加 `processStatusesAtTurnEnd` (触发效果 + 自动递减)
- ✅ 更新所有敌人 AI (使用 statuses.stacks)
- ✅ 重构 `BattleScreen.buildStatusLine` (注册表驱动)
- ✅ 修复编译警告
- ✅ 所有测试通过 (build, startup, integration)

**测试结果**: 所有测试通过，无编译警告

---
- [x] 易伤/虚弱/力量/敏捷/中毒 全部可通过注册表扩展
- [x] `BattleScreen` 状态展示由 registry 驱动（无硬编码 if 链）
- [x] `swift build` 成功
- [x] `./.cursor/Scripts/test_game.sh` 成功

---

## P3: 敌人系统统一 ⭐⭐ ✅ **已完成**

> **实施日期**: 2026-01-03  
> **状态**: ✅ 完成并通过所有测试  
> **Commits**: 已合并（需补充具体哈希）

### P3 重新审查：当前实现的问题（来自真实代码）

我已核对当前实现：

- `Sources/GameCore/Enemies/EnemyKind.swift` + `EnemyData.get()`：新增敌人要改 `switch`
- `Sources/GameCore/Enemies/EnemyAI.swift` + `EnemyAIFactory`：引擎需要“按种类选择 AI”
- `Sources/GameCore/Battle/BattleEngine.swift`：敌人执行逻辑依赖 `EnemyIntent` 的 `switch`（与卡牌类似的扩展点）
- debuff/buff 目前用字符串（如 `"虚弱"`, `"仪式"`），会和 P2 的 `StatusID/StatusRegistry` 脱节

结论：P3 必须把敌人域重构为与 P1/P2 同一条主线：**EnemyID + EnemyDefinition + EnemyRegistry + Move 产出 BattleEffect**，并彻底删除旧扩展点。

### P3 目标（破坏性：不保留 EnemyKind/EnemyAI/EnemyData）

- **彻底删除**：`EnemyKind` / `EnemyData` / `EnemyAI` / `EnemyBehaviors` / `EnemyAIFactory` / `createEnemy(kind:)`
- 建立 **EnemyID / EnemyDefinition / EnemyRegistry / EnemyPool** 的敌人框架
- 敌人的 AI 不再是工厂：直接由 `EnemyDefinition.chooseMove(snapshot, rng)` 决策
- 敌人行动不再 `switch EnemyIntent` 执行：**统一执行 `[BattleEffect]`（走 BattleEngine 的 apply(effect:)）**

### 当前架构问题

```
当前（分散）：
┌───────────────┐    ┌─────────────┐    ┌─────────────┐
│  EnemyKind    │    │  EnemyData  │    │  EnemyAI    │
│  (枚举)        │    │  (switch)    │    │  (协议)      │
└───────┬───────┘    └──────┬──────┘    └──────┬──────┘
        │                    │                  │
        └────────────────────┴──────────────────┘
                             │
                    添加新敌人需要修改 3 处

目标（统一）：
┌───────────────────────────────────────┐
│       EnemyDefinition                 │
│  ├── id, displayName                  │
│  ├── hpRange, baseAttack              │
│  └── chooseMove() -> EnemyMove        │
└───────────────────────────────────────┘
        │
添加新敌人只需创建 1 个结构体 + 注册
```

### 新架构设计

```
Sources/GameCore/
├── Kernel/
│   └── IDs.swift                     # EnemyID（强类型，P3 新增）
│
├── Enemies/
│   ├── EnemyDefinition.swift         # 敌人定义协议（数据+AI）
│   ├── EnemyMove.swift               # 敌人计划行动（intent + effects）
│   ├── EnemyRegistry.swift           # 注册表：EnemyID -> Definition
│   ├── EnemyPool.swift               # 遭遇表（只产出 EnemyID）
│   └── Definitions/
│       └── Act1/
│           ├── JawWorm.swift
│           ├── Cultist.swift
│           ├── LouseGreen.swift
│           ├── LouseRed.swift
│           └── SlimeMediumAcid.swift
│
└── Battle/
    └── BattleEngine.swift            # 破坏性重构：不再持有 enemyAI，不再 switch intent 执行
```

### 协议设计

```swift
// ═══════════════════════════════════════════════════════════════
// IDs.swift / EnemyMove.swift / EnemyDefinition.swift（P3 核心接口）
// ═══════════════════════════════════════════════════════════════

/// 敌人 ID（强类型，禁止散落字符串）
public struct EnemyID: Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.rawValue = value }
}

/// 敌人意图（仅用于 UI 显示）
/// 注意：意图不是执行逻辑，执行逻辑靠 effects
public struct EnemyIntent: Sendable, Equatable {
    public let icon: String
    public let text: String
    public let previewDamage: Int?
}

/// 敌人计划行动（一次“计划”，包含 intent + effects）
public struct EnemyMove: Sendable, Equatable {
    public let intent: EnemyIntent
    public let effects: [BattleEffect]
}

/// 敌人定义协议（数据 + AI）
/// 约束：只能产出 EnemyMove（effects 由 BattleEngine 执行并发事件）
public protocol EnemyDefinition: Sendable {
    static var id: EnemyID { get }
    static var name: String { get }                 // UI 名称（中文）
    static var hpRange: ClosedRange<Int> { get }    // 生成实例时使用

    /// AI：根据快照选择下一步行动（可使用 rng，但必须把随机结果固化进 effects）
    static func chooseMove(snapshot: BattleSnapshot, rng: inout SeededRNG) -> EnemyMove
}
```

### 敌人实现示例

```swift
// 示例 1：下颚虫（JawWorm）
// 行为模式（简化版）：攻击（base 11）或给自己加力量（strength +3）
// 注意：这里的攻击强度修正（力量/虚弱/易伤）由 P2 的状态系统统一在 DamageCalculator 里处理
public struct JawWorm: EnemyDefinition {
    public static let id: EnemyID = "jaw_worm"
    public static let name: String = "下颚虫"
    public static let hpRange: ClosedRange<Int> = 40...44

    public static func chooseMove(snapshot: BattleSnapshot, rng: inout SeededRNG) -> EnemyMove {
        let roll = rng.nextInt(upperBound: 100)

        // 第一回合：75% 攻击，否则加力量
        if snapshot.turn == 1 {
            if roll < 75 {
                return EnemyMove(
                    intent: EnemyIntent(icon: "⚔️", text: "攻击 11", previewDamage: 11),
                    effects: [.dealDamage(target: .player, base: 11)]
                )
            } else {
                return EnemyMove(
                    intent: EnemyIntent(icon: "💪", text: "力量 +3", previewDamage: nil),
                    effects: [.applyStatus(target: .enemy, statusId: "strength", stacks: 3)]
                )
            }
        }

        // 后续回合：45% 攻击、30% 加力量、25% 猛扑（base 7）
        if roll < 45 {
            return EnemyMove(
                intent: EnemyIntent(icon: "⚔️", text: "攻击 11", previewDamage: 11),
                effects: [.dealDamage(target: .player, base: 11)]
            )
        } else if roll < 75 {
            return EnemyMove(
                intent: EnemyIntent(icon: "💪", text: "力量 +3", previewDamage: nil),
                effects: [.applyStatus(target: .enemy, statusId: "strength", stacks: 3)]
            )
        } else {
            return EnemyMove(
                intent: EnemyIntent(icon: "⚔️", text: "猛扑 7", previewDamage: 7),
                effects: [.dealDamage(target: .player, base: 7)]
            )
        }
    }
}

// 示例 2：酸液史莱姆（SlimeMediumAcid）
// 行为模式（简化版）：攻击（base 10）或“涂抹”（base 7 + 给玩家虚弱 1）
public struct SlimeMediumAcid: EnemyDefinition {
    public static let id: EnemyID = "slime_medium_acid"
    public static let name: String = "酸液史莱姆"
    public static let hpRange: ClosedRange<Int> = 28...32

    public static func chooseMove(snapshot: BattleSnapshot, rng: inout SeededRNG) -> EnemyMove {
        let roll = rng.nextInt(upperBound: 100)
        if roll < 70 {
            return EnemyMove(
                intent: EnemyIntent(icon: "⚔️", text: "攻击 10", previewDamage: 10),
                effects: [.dealDamage(target: .player, base: 10)]
            )
        } else {
            return EnemyMove(
                intent: EnemyIntent(icon: "⚔️💀", text: "涂抹 7 + 虚弱 1", previewDamage: 7),
                effects: [
                    .dealDamage(target: .player, base: 7),
                    .applyStatus(target: .player, statusId: "weak", stacks: 1)
                ]
            )
        }
    }
}
```

### EnemyRegistry

```swift
// ═══════════════════════════════════════════════════════════════
// EnemyRegistry.swift - 敌人注册表
// ═══════════════════════════════════════════════════════════════

/// 敌人注册表
public enum EnemyRegistry {

    private static let defs: [EnemyID: any EnemyDefinition.Type] = [
        JawWorm.id: JawWorm.self,
        SlimeMediumAcid.id: SlimeMediumAcid.self,
        // ... 其余敌人在这里注册（每新增一个敌人，只新增 definition 文件 + 在这里加一行）
    ]

    public static func get(_ id: EnemyID) -> (any EnemyDefinition.Type)? { defs[id] }

    /// 计划中：用于引擎/测试的强制查找（找不到就直接失败，避免静默 fallback）
    public static func require(_ id: EnemyID) -> any EnemyDefinition.Type { defs[id]! }
}
```

### EnemyPool 重构

```swift
// ═══════════════════════════════════════════════════════════════
// EnemyPool.swift - 使用 EnemyRegistry
// ═══════════════════════════════════════════════════════════════

/// 第一章敌人池
public enum Act1EnemyPool {
    /// 弱敌人 ID 列表（注意：这里不生成 Entity，只负责“抽到谁”）
    public static let weak: [EnemyID] = [
        JawWorm.id,
        // Cultist.id, LouseGreen.id, LouseRed.id ...
    ]

    /// 中等敌人 ID 列表
    public static let medium: [EnemyID] = [
        SlimeMediumAcid.id
    ]

    /// 所有敌人
    public static let all: [EnemyID] = weak + medium

    /// 随机选择弱敌人（只返回 EnemyID）
    public static func randomWeak(rng: inout SeededRNG) -> EnemyID {
        weak[rng.nextInt(upperBound: weak.count)]
    }

    /// 随机选择任意敌人（只返回 EnemyID）
    public static func randomAny(rng: inout SeededRNG) -> EnemyID {
        all[rng.nextInt(upperBound: all.count)]
    }
}
```

### BattleEngine 修改

```swift
// BattleEngine（P3 之后）
// - 不再持有 `enemyAI`
// - 不再 switch EnemyIntent 来执行动作
// - 计划阶段 chooseMove（用 rng），执行阶段只 apply effects（不再随机）

private var plannedEnemyMove: EnemyMove?

private func planEnemyMove() {
    // enemyId 是 Entity 上的稳定 EnemyID（P3 会把 kind 替换掉）
    let def = EnemyRegistry.require(state.enemy.enemyId!)

    let snapshot = BattleSnapshot(
        turn: state.turn,
        player: state.player,
        enemy: state.enemy,
        energy: state.energy
    )

    let move = def.chooseMove(snapshot: snapshot, rng: &rng)
    state.enemy.intent = move.intent           // 给 UI 显示
    plannedEnemyMove = move                   // 保存计划，保证可复现

    emit(.enemyIntent(
        enemyId: state.enemy.id,
        action: move.intent.text,
        damage: move.intent.previewDamage ?? 0
    ))
}

private func executeEnemyTurn() {
    guard let move = plannedEnemyMove else { return }

    emit(.enemyAction(enemyId: state.enemy.id, action: move.intent.text))
    for effect in move.effects {
        apply(effect)   // apply(effect:) 来自 P1（统一效果执行入口）
    }

    plannedEnemyMove = nil
}
```

### P3 实施步骤

- P3.1 在 `Kernel/IDs.swift` 增加 `EnemyID`（强类型）
- P3.2 新建 `EnemyIntent`/`EnemyMove`/`EnemyDefinition`/`EnemyRegistry`
- P3.3 迁移现有 Act1 的敌人实现为 Definition（每个敌人一个文件，输出 `EnemyMove(effects:)`）
- P3.4 `EnemyPool` 破坏性重写：只返回 `EnemyID`（不生成 `Entity`）
- P3.5 敌人实例生成：用 `hpRange + rng` 生成 HP，实例 `id` 使用“可复现计数器/组合字符串”，**禁止 UUID/Foundation**
- P3.6 `Entity` 破坏性改动：`kind: EnemyKind?` → `enemyId: EnemyID?`（并配合 P2 的 `statuses`）
- P3.7 `BattleEngine` 破坏性改动：
  - 删除 `enemyAI` 成员与 `EnemyAIFactory`
  - 增加 `plannedEnemyMove: EnemyMove?`
  - 回合开始 `planEnemyMove()`，敌人回合执行 `move.effects`（统一走 `apply(effect:)`）
- P3.8 `GameCLI`/`RunState` 里挑敌人逻辑改为 `EnemyID`（Act1EnemyPool.randomWeak/randomAny）
- P3.9 添加 2 个新敌人验证扩展性（新增文件 + 注册即可）
- P3.10 验证：`swift build` + `./.cursor/Scripts/test_game.sh`

### P3 验收标准（必须全部通过）

- [x] ✅ 代码库中不存在：`EnemyKind.swift`, `EnemyData.swift`, `EnemyAI.swift`, `EnemyBehaviors.swift`, `EnemyAIFactory`
- [x] ✅ `EnemyRegistry` 使用 `EnemyID` 作为 key，新增敌人只需新增 Definition + 注册
- [x] ✅ `EnemyPool` 只返回 `EnemyID`（不生成 `Entity`）
- [x] ✅ `BattleEngine` 不再 switch intent 执行敌人动作（统一执行 move.effects）
- [x] ✅ 敌人行动的随机性只发生在 plan 阶段（可复现）
- [x] ✅ `swift build` 成功
- [x] ✅ `./.cursor/Scripts/test_game.sh` 成功

### P3 实施总结 ✅

**完成内容**:
- ✅ 添加 `EnemyID` 到类型系统
- ✅ 创建敌人框架 (EnemyMove, EnemyDefinition, EnemyRegistry)
- ✅ 实现 5 个敌人定义
- ✅ 重构 Entity, EnemyPool, BattleEngine, BattleScreen, GameCLI
- ✅ 删除所有旧敌人系统文件
- ✅ 所有测试通过

**测试结果**: 所有测试通过，无编译错误

---

## P4: 遗物系统设计 ⭐ ✅ **已完成**

> **实施日期**: 2026-01-03  
> **状态**: ✅ 完成并通过所有测试  
> **Commits**: 已合并（需补充具体哈希）

### P4 重新审查：当前方案的问题（作为“框架”还不够）

当前 P4 的写法存在几个“框架级”问题：

- **重复造轮子**：`RelicEffectResult` 本质上就是另一套 “效果枚举”，会与 P1 的 `BattleEffect` 分裂
- **Context 过大且全是 Optional**：`RelicTriggerContext` 同时塞 battle/run/card/damage 信息，调用方容易传错/漏传
- **类型不统一**：状态还是字符串（`"strength"`），与 P2 的 `StatusID/StatusRegistry` 不一致
- **触发点没有边界**：battle 触发与 run 触发混在同一套 trigger + result 里，后期会变得不可维护

结论：遗物应该是“插件/Hook”，**统一产出 Effect**，并且分清 battle 与 run 两个层级。

### P4 目标（破坏性：统一到 Hook + Effect）

- 建立 **RelicID / RelicDefinition / RelicRegistry / RelicManager** 的遗物框架
- 触发采用 **BattleTrigger（战斗层）/ RunTrigger（冒险层）** 分离
- 遗物效果统一产出：
  - battle 内：`[BattleEffect]`
  - run 内：`[RunEffect]`（P5/P6 会补齐 run 框架）
- `BattleEngine` 只负责：在触发点收集遗物效果 → `apply(effect:)` 执行 → emit `BattleEvent`

### 新架构设计

```
Sources/GameCore/
├── Kernel/
│   ├── IDs.swift                     # RelicID（强类型，P4 新增）
│   ├── BattleTrigger.swift           # 战斗触发点（P4 新增）
│   ├── BattleEffect.swift            # 统一效果（P4 需要补充 heal 等 case）
│   └── RunEffect.swift               # RunEffect（P5/P6 补齐）
│
├── Relics/
│   ├── RelicDefinition.swift         # 遗物定义协议（Hook：trigger -> effects）
│   ├── RelicRegistry.swift           # 注册表：RelicID -> Definition
│   ├── RelicManager.swift            # 管理器：持有 RelicID 列表并处理触发
│   └── Definitions/
│       ├── Starter.swift             # 起始遗物
│       ├── Common.swift              # 普通遗物
│       └── Boss.swift                # Boss 遗物
│
└── Battle/
    └── BattleEngine.swift            # 触发 BattleTrigger → 收集 relic effects → apply(effect:)
```

### 协议设计

```swift
// ═══════════════════════════════════════════════════════════════
// IDs.swift / BattleTrigger.swift / RelicDefinition.swift（P4 核心接口）
// ═══════════════════════════════════════════════════════════════

/// 遗物 ID（强类型）
public struct RelicID: Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.rawValue = value }
}

/// 战斗触发点（只包含 battle 相关）
/// 说明：run 相关触发点（进入房间/获得金币等）会在 P5/P6 的 RunEngine 中定义 RunTrigger/RunEffect
public enum BattleTrigger: Sendable, Equatable {
    case battleStart
    case battleEnd(won: Bool)
    case turnStart(turn: Int)
    case turnEnd(turn: Int)
    case cardPlayed(cardId: CardID)
    case cardDrawn(cardId: CardID)
    case damageDealt(amount: Int)
    case damageTaken(amount: Int)
    case blockGained(amount: Int)
    case enemyKilled
}

/// 遗物定义协议（Hook）
/// 约束：只能产出 [BattleEffect]，不直接修改 BattleState，也不直接 emit 事件
public protocol RelicDefinition: Sendable {
    static var id: RelicID { get }
    static var name: String { get }         // UI 名称（中文）
    static var description: String { get }
    static var rarity: RelicRarity { get }
    static var icon: String { get }

    /// 触发：由 BattleEngine 在对应时机调用
    static func onBattleTrigger(_ trigger: BattleTrigger, snapshot: BattleSnapshot) -> [BattleEffect]
}

public enum RelicRarity: String, Sendable {
    case starter = "起始"
    case common = "普通"
    case uncommon = "罕见"
    case rare = "稀有"
    case boss = "Boss"
    case event = "事件"
}
```

### 遗物实现示例

```swift
// ═══════════════════════════════════════════════════════════════
// Relics/Definitions/*.swift - 遗物实现示例
// ═══════════════════════════════════════════════════════════════

/// 燃烧之血（铁甲战士起始遗物）
/// 效果：战斗结束时恢复 6 HP
public struct BurningBloodRelic: RelicDefinition {
    public static let id: RelicID = "burning_blood"
    public static let name = "燃烧之血"
    public static let description = "战斗结束时恢复 6 点生命值"
    public static let rarity: RelicRarity = .starter
    public static let icon = "🔥"

    public static func onBattleTrigger(_ trigger: BattleTrigger, snapshot: BattleSnapshot) -> [BattleEffect] {
        guard case .battleEnd(let won) = trigger, won else { return [] }
        // 说明：这里需要 BattleEffect.heal（P4 会补充到 BattleEffect）
        return [.heal(target: .player, amount: 6)]
    }
}

/// 金刚杵
/// 效果：战斗开始时获得 1 点力量
public struct VajraRelic: RelicDefinition {
    public static let id: RelicID = "vajra"
    public static let name = "金刚杵"
    public static let description = "战斗开始时获得 1 点力量"
    public static let rarity: RelicRarity = .common
    public static let icon = "💎"

    public static func onBattleTrigger(_ trigger: BattleTrigger, snapshot: BattleSnapshot) -> [BattleEffect] {
        guard case .battleStart = trigger else { return [] }
        return [.applyStatus(target: .player, statusId: "strength", stacks: 1)]
    }
}

/// 灯笼
/// 效果：战斗开始时获得 1 点能量
public struct LanternRelic: RelicDefinition {
    public static let id: RelicID = "lantern"
    public static let name = "灯笼"
    public static let description = "战斗开始时获得 1 点能量"
    public static let rarity: RelicRarity = .common
    public static let icon = "🏮"

    public static func onBattleTrigger(_ trigger: BattleTrigger, snapshot: BattleSnapshot) -> [BattleEffect] {
        guard case .battleStart = trigger else { return [] }
        return [.gainEnergy(amount: 1)]
    }
}
```

### RelicManager

```swift
// ═══════════════════════════════════════════════════════════════
// RelicManager.swift - 遗物管理器
// ═══════════════════════════════════════════════════════════════

/// 遗物管理器
/// 管理玩家持有的遗物，处理触发事件
public struct RelicManager: Sendable {
    /// 持有的遗物 ID 列表
    private var relicIds: [RelicID] = []
    
    public init() {}
    
    /// 添加遗物
    public mutating func add(_ relicId: RelicID) {
        guard !relicIds.contains(relicId) else { return }
        relicIds.append(relicId)
    }
    
    /// 移除遗物
    public mutating func remove(_ relicId: RelicID) {
        relicIds.removeAll { $0 == relicId }
    }
    
    /// 是否拥有指定遗物
    public func has(_ relicId: RelicID) -> Bool {
        relicIds.contains(relicId)
    }

    /// 战斗触发：收集所有遗物产出的 BattleEffect（由 BattleEngine 执行）
    public func onBattleTrigger(_ trigger: BattleTrigger, snapshot: BattleSnapshot) -> [BattleEffect] {
        var effects: [BattleEffect] = []

        for relicId in relicIds {
            let def = RelicRegistry.require(relicId)
            effects.append(contentsOf: def.onBattleTrigger(trigger, snapshot: snapshot))
        }

        return effects
    }
}
```

### RelicRegistry

```swift
// ═══════════════════════════════════════════════════════════════
// RelicRegistry.swift - 遗物注册表
// ═══════════════════════════════════════════════════════════════

public enum RelicRegistry {
    private static let defs: [RelicID: any RelicDefinition.Type] = [
        BurningBloodRelic.id: BurningBloodRelic.self,
        VajraRelic.id: VajraRelic.self,
        LanternRelic.id: LanternRelic.self
    ]

    public static func get(_ id: RelicID) -> (any RelicDefinition.Type)? { defs[id] }
    public static func require(_ id: RelicID) -> any RelicDefinition.Type { defs[id]! }
}
```

### BattleEngine 集成

```swift
// BattleEngine：遗物触发点示例
// 约束：遗物不直接改状态/不 emit 事件，只产出 BattleEffect
// BattleEngine 统一执行：for effect in effects { apply(effect) }

public func startBattle() {
    events.removeAll()
    emit(.battleStarted)

    let snapshot = BattleSnapshot(
        turn: state.turn,
        player: state.player,
        enemy: state.enemy,
        energy: state.energy
    )

    // battleStart 触发遗物
    for effect in relicManager.onBattleTrigger(.battleStart, snapshot: snapshot) {
        apply(effect) // apply(effect:) 来自 P1（统一效果执行入口）
    }

    startNewTurn()
}

private func handleBattleEnd(won: Bool) {
    let snapshot = BattleSnapshot(
        turn: state.turn,
        player: state.player,
        enemy: state.enemy,
        energy: state.energy
    )

    for effect in relicManager.onBattleTrigger(.battleEnd(won: won), snapshot: snapshot) {
        apply(effect)
    }
}
```

### 实施步骤

| 步骤 | 内容 | 复杂度 | 预计时间 |
|------|------|--------|----------|
| P4.1 | 在 `Kernel/IDs.swift` 增加 `RelicID`（强类型） | ⭐ | 10分钟 |
| P4.2 | 创建 `Kernel/BattleTrigger.swift`（Battle 触发点枚举） | ⭐ | 15分钟 |
| P4.3 | 扩展 `Kernel/BattleEffect.swift`：补齐遗物需要的效果（至少 `heal`） | ⭐⭐ | 15分钟 |
| P4.4 | 创建 `RelicDefinition` 协议（onBattleTrigger → [BattleEffect]） | ⭐ | 20分钟 |
| P4.5 | 创建 `RelicRegistry`（RelicID → Definition） | ⭐ | 15分钟 |
| P4.6 | 创建 `RelicManager`（持有 RelicID 列表，负责触发汇总） | ⭐⭐ | 25分钟 |
| P4.7 | 实现 3 个基础遗物（BurningBlood / Vajra / Lantern） | ⭐ | 30分钟 |
| P4.8 | 修改 `RunState` 添加 `RelicManager`（冒险持久状态） | ⭐ | 15分钟 |
| P4.9 | 修改 `BattleEngine`：在 battleStart/battleEnd/turnStart 等触发点调用 relicManager 并 apply effects | ⭐⭐ | 40分钟 |
| P4.10 | CLI UI：在战斗界面/设置页显示当前遗物（名称 + 图标 + 描述） | ⭐ | 25分钟 |
| P4.11 | 验证所有遗物触发点与效果正确 | ⭐ | 20分钟 |
| **总计** | | | **~3.5小时** |

### 验收标准

 - [x] ✅ `RelicRegistry` 使用 `RelicID` 注册遗物，新增遗物只需新增 Definition + 注册
 - [x] ✅ `RelicManager` 不产出 BattleEvent（只产出 BattleEffect 列表）
 - [x] ✅ `BattleTrigger` 只包含 battle 层触发点（run 层触发点留给 P5/P6）
 - [x] ✅ `BattleEffect` 已补齐遗物所需效果（至少支持 heal）
 - [x] ✅ BurningBlood：胜利后战斗结束恢复 6 HP
 - [x] ✅ Vajra：战斗开始获得 1 点力量
 - [x] ✅ Lantern：战斗开始获得 1 点能量
 - [x] ✅ `swift build` 成功
 - [x] ✅ `./.cursor/Scripts/test_game.sh` 成功

### P4 实施总结 ✅

**完成内容**:
- ✅ 添加 `RelicID` 到类型系统
- ✅ 创建 `BattleTrigger` 枚举（战斗触发点）
- ✅ 创建遗物框架 (RelicDefinition, RelicRegistry, RelicManager)
- ✅ 实现 3 个基础遗物 (BurningBlood, Vajra, Lantern)
- ✅ 在 `RunState` 添加 `RelicManager`
- ✅ 在 `BattleEngine` 集成遗物触发:
  - battleStart 触发
  - turnStart 触发
  - battleEnd 触发（含胜利/失败）
  - triggerRelics helper 方法
- ✅ 更新 `GameCLI` 传递 relicManager
- ✅ 所有测试通过

**测试结果**: 所有测试通过，无编译错误

---

## P5: Run/房间/地图流程协议化 ⭐⭐ ✅ **已完成**

> **实施日期**: 2026-01-03  
> **状态**: ✅ 完成并通过所有测试  
> **Commit**: 9e9e791

### 目标

- **消灭 GameCLI 的 RoomType 分支**：删除 `GameCLI.runLoop` 中 `switch selectedNode.roomType { ... }`
- **RoomType 保留 enum**：类型相对稳定，但"行为"通过 Handler/Registry 扩展
- **地图生成策略协议化**：为 Act2/更高难度预留 `MapGenerating` 扩展点（保持可复现）

### 新架构设计（已实现）

```
Sources/GameCore/
├── Map/
│   ├── MapGenerating.swift            # 地图生成策略协议（P5 新增）✅
│   └── MapGenerator.swift             # 默认实现（Branching）
│
└── [保持] RoomType.swift, MapNode.swift

Sources/GameCLI/
├── Flow/
│   ├── RoomHandling.swift             # RoomHandling 协议 + RoomContext（P5 新增）✅
│   └── RoomHandlerRegistry.swift      # RoomType -> handler（P5 新增）✅
│
└── Rooms/
    └── Handlers/
        ├── StartRoomHandler.swift     # ✅
        ├── BattleRoomHandler.swift    # ✅
        ├── EliteRoomHandler.swift     # ✅
        ├── RestRoomHandler.swift      # ✅
        └── BossRoomHandler.swift      # ✅
```

### 关键协议（已实现）

```swift
// GameCore/Map/MapGenerating.swift
public protocol MapGenerating: Sendable {
    func generate(seed: UInt64, rows: Int) -> [MapNode]
}

// GameCLI/Flow/RoomHandling.swift
protocol RoomHandling {
    func run(node: MapNode, runState: inout RunState, context: RoomContext) -> RoomRunResult
}

struct RoomContext {
    var rng: SeededRNG
    let relicManager: RelicManager
    let historyService: HistoryService  // P6 bug fix 添加
}

enum RoomRunResult {
    case completedNode
    case runEnded(won: Bool)
}
```

### 实施步骤

- [x] ✅ P5.1 新建 `MapGenerating` 协议；让现有 `MapGenerator.generateBranching` 成为默认实现
- [x] ✅ P5.2 新建 `RoomHandlerRegistry` + 5 个 handler（start/battle/elite/rest/boss）
- [x] ✅ P5.3 改造 `GameCLI.runLoop`：用 registry 选择 handler 并执行，彻底删除 `switch roomType`
- [x] ✅ P5.4 验证：地图选择→战斗→休息→Boss→通关/失败流程全部可跑通

### 验收标准（全部通过）

- [x] ✅ `GameCLI.runLoop` 不再包含 `switch selectedNode.roomType`
- [x] ✅ 删除了 3 个私有方法（handleBattleNode, handleRestNode, handleBossNode - 95+ 行）
- [x] ✅ 新增一个房间行为只需新增 handler + 注册（不改 runLoop）
- [x] ✅ `swift build` 成功
- [x] ✅ `./.cursor/Scripts/test_game.sh` 成功（6/6 套件通过）

### 实施总结

**完成内容**:
- ✅ 创建 `MapGenerating` 协议和 `BranchingMapGenerator` 默认实现
- ✅ 创建 `RoomHandling` 协议和 `RoomContext`
- ✅ 创建 `RoomHandlerRegistry`
- ✅ 实现 5 个房间 handler: Start, Battle, Elite, Rest, Boss
- ✅ 重构 `GameCLI.runLoop`:
  - 移除 `switch selectedNode.roomType` (80+ 行)
  - 移除 3 个私有方法 (95+ 行)
  - 使用 registry-based handler selection

**架构改进**:
- **Before**: GameCLI.runLoop 包含 80+ 行 switch 分支 + 3 个私有方法（95+ 行）
- **After**: 使用 registry 选择 handler，房间逻辑封装在 5 个独立文件中

**测试结果**: 6/6 测试套件通过，无编译错误

---
## P6: 持久化与 I/O 协议化 ⭐⭐ ✅ **已完成**

> **实施日期**: 2026-01-04  
> **状态**: ✅ 完成并通过所有测试  
> **Commit**: [即将提交]

### 目标

- **移除单例**：删除 `HistoryManager.shared`，改为依赖注入（接口优于单例）
- **把 I/O 隔离在 GameCLI**：GameCore 只定义协议/数据结构；文件读写/JSON 编解码留在 GameCLI
- **为 Run 存档预留扩展点**：引入 `RunSaveStore` 协议（P6 建接口，后续实现）

### 新架构设计

```
Sources/GameCore/
└── Persistence/
    ├── BattleHistoryStore.swift       # 协议（P6 新增）
    └── RunSaveStore.swift             # 协议（P6 新增）

Sources/GameCLI/
└── Persistence/
    ├── FileBattleHistoryStore.swift   # JSON 文件实现（P6 新增）
    └── （P7）FileRunSaveStore.swift   # Run 存档文件实现（在 P7 真正落地）
```

### 关键协议（最小示例）

```swift
// GameCore/Persistence/BattleHistoryStore.swift
public protocol BattleHistoryStore: Sendable {
    func load() throws -> [BattleRecord]
    func append(_ record: BattleRecord) throws
    func clear() throws
}
```

### 实施步骤

- P6.1 在 GameCore 定义 `BattleHistoryStore` 协议
- P6.2 在 GameCLI 实现 `FileBattleHistoryStore`（复用现有存储路径逻辑）
- P6.3 用 `HistoryService`（或同名管理器）替代 `HistoryManager.shared`，由 `GameCLI.main()` 注入
- P6.4 为 Run 存档定义 `RunSaveStore` 协议（先不实现具体存档格式，P7 落地）

### 验收标准（必须全部通过）

- [x] ✅ 代码库中不存在 `HistoryManager.shared`
- [x] ✅ History 读写走 `BattleHistoryStore` 协议（可替换 mock）
- [x] ✅ `swift build` 成功
- [x] ✅ `./.cursor/Scripts/test_game.sh` 成功

---

## P7: Run 存档系统（Save/Load）⭐⭐

### 目标

- 支持 **“继续上次冒险”**（主菜单入口）
- 存档是 **Run 维度**（先不做 mid-battle 存档，避免需要序列化 BattleState）
- 存档不做向后兼容：版本不匹配就提示“存档已过期，需要重新开局”（符合破坏性策略）

### 新架构设计

```
Sources/GameCore/
└── Run/
    ├── RunSnapshot.swift              # Codable 快照（P7 新增）
    └── RunSaveVersion.swift           # 版本号（P7 新增）

Sources/GameCLI/
└── Persistence/
    └── FileRunSaveStore.swift         # RunSaveStore 文件实现（P7 落地）
```

### 关键数据结构（最小示例）

```swift
// GameCore/Run/RunSaveVersion.swift
public enum RunSaveVersion {
    public static let current = 1
}

// GameCore/Run/RunSnapshot.swift
public struct RunSnapshot: Codable, Sendable {
    public let version: Int
    public let seed: UInt64
    public let floor: Int

    // map / node
    public let map: [MapNode]
    public let currentNodeId: String?

    // player / deck
    public let player: Entity
    public let deck: [Card]

    // relics（P4 后加入）
    public let relicIds: [RelicID]

    // 说明：如果后续引入 run-level RNG（奖励/事件/商店），需要把 RNG state 一并放进 snapshot
}

// GameCore/Persistence/RunSaveStore.swift（P6 已建协议，这里只说明用途）
public protocol RunSaveStore: Sendable {
    func load() throws -> RunSnapshot?
    func save(_ snapshot: RunSnapshot) throws
    func clear() throws
}
```

### 触发时机（建议）

- **节点完成后**（`RunState.completeCurrentNode()` 之后）自动保存
- **战斗胜利后**（更新 playerHP、完成节点后）自动保存
- **冒险结束**（通关/死亡）清除存档（可选）

### 实施步骤

- P7.1 在 GameCore 新增 `RunSnapshot`（Codable）与 `RunSaveVersion`
- P7.2 在 GameCLI 实现 `FileRunSaveStore`（读写 JSON）
- P7.3 主菜单新增 “继续上次冒险”（若无存档则隐藏/置灰）
- P7.4 `GameCLI.runLoop`：在关键节点自动 `save(snapshot)`；在 run 结束时按策略清理
- P7.5 验证：退出程序 → 再次启动 → 可继续同一张地图同一套 deck/hp 进度

### 验收标准（必须全部通过）

- [ ] 主菜单可“继续上次冒险”
- [ ] 存档版本不匹配时有明确提示，并不会崩溃
- [ ] `swift build` 成功
- [ ] `./.cursor/Scripts/test_game.sh` 成功

## ⚠️ 风险与注意事项

### 1. 破坏性重构影响面（必须接受）

- **会删掉大量现有 public API**：尤其是 `CardKind` / `EnemyKind` / `EnemyData.get()` 这类“枚举 + switch”的扩展点
- **会强制全项目一次性迁移到新框架**：不保留旧入口，不做兼容层
- **战绩数据（BattleRecord）不存卡牌/敌人 ID**：目前无需迁移 battle_history.json（但如果未来新增 Run 存档，则需要另起一份迁移计划）

### 2. 性能考虑

- 协议的动态派发可能比枚举的静态派发稍慢
- 使用 `static` 方法和属性确保零成本抽象
- 对于热路径（如伤害计算），可以考虑使用 `@inlinable`
- `StatusContainer` 使用 `Dictionary`，频繁访问时考虑缓存

### 3. 测试策略

每完成一个优先级后：
1. 运行 `swift build` 确保编译通过
2. 运行现有测试：`./.cursor/Scripts/test_game.sh`
3. 手动测试关键流程：
   - P1 后：使用所有卡牌，验证效果正确
   - P2 后：验证易伤、虚弱、力量、中毒效果
   - P3 后：与所有敌人战斗，验证 AI 行为
   - P4 后：验证遗物触发和效果
   - P5 后：地图选择→房间执行→通关/失败流程（确认 runLoop 不再 switch roomType）
   - P6 后：历史记录读写/清空正常（确认无 `HistoryManager.shared`）
   - P7 后：继续冒险/存档版本过期提示/自动保存时机正确

---

## 📋 检查清单

### P1 完成后检查
- [ ] `CardRegistry.get(CardID("strike"))` 返回正确定义
- [ ] `Card(id: "strike_1", cardId: "strike")` 正确工作（实例 ID + CardID 分离）
- [ ] BattleEngine 通过 `BattleEffect` 管线执行卡牌效果（无卡牌 switch）
- [ ] BattleScreen 不再包含“按卡牌种类 switch 拼描述”的逻辑，改为 registry/rulesText 驱动
- [ ] 添加新卡牌只需新增 `CardDefinition` + 在 `CardRegistry` 注册

### P2 完成后检查
- [ ] `Entity` 不再含 `vulnerable/weak/strength` 字段，统一为 `statuses: StatusContainer`
- [ ] `StatusContainer` 纯数据（不产出 BattleEvent/不做 tick）
- [ ] `DamageCalculator` 按 phase+priority 应用状态修正（确定性）
- [ ] 中毒在 turnEnd 通过 `StatusDefinition.onTurnEnd` 产出 `BattleEffect`，由引擎执行

### P3 完成后检查
- [ ] `EnemyRegistry.get(EnemyID("jaw_worm"))` 返回正确定义
- [ ] `EnemyPool.randomWeak()` 只返回 `EnemyID`（不生成 Entity）
- [ ] BattleEngine 通过 `EnemyMove(effects:)` 执行敌人行动（不再 switch intent）
- [ ] 旧代码已删除：EnemyKind/EnemyData/EnemyAI/EnemyBehaviors/EnemyAIFactory

### P4 完成后检查
- [ ] `RelicManager.onBattleTrigger(.battleStart, snapshot:)` 正确触发遗物并返回 `[BattleEffect]`
- [ ] 燃烧之血：胜利后战斗结束恢复 6 HP
- [ ] 金刚杵战斗开始 +1 力量
- [ ] 灯笼战斗开始 +1 能量

### P5 完成后检查
- [ ] `GameCLI.runLoop` 不再包含 `switch selectedNode.roomType`
- [ ] RoomHandlerRegistry 已注册 start/battle/rest/boss 的 handler
- [ ] 冒险流程可完整跑通：地图选择 → 战斗/休息 → Boss → 通关/失败

### P6 完成后检查
- [x] ✅ 代码库中不存在 `HistoryManager.shared`
- [x] ✅ History 读写通过 `BattleHistoryStore` 注入（可替换 mock）
- [x] ✅ 设置菜单（history/stats/clear）功能正常

## P6 实施总结 ✅

**完成内容**:
- ✅ 创建 `BattleHistoryStore` 协议（GameCore）
- ✅ 创建 `RunSaveStore` 协议（GameCore，P7 预留）
- ✅ 实现 `FileBattleHistoryStore`（GameCLI）
- ✅ 创建 `HistoryService` 替代单例
- ✅ 删除 `HistoryManager.shared`
- ✅ 更新所有 Screen 使用依赖注入
- ✅ 所有测试通过
- ✅ **Bug修复**: 添加战斗记录保存到所有房间处理器（BattleRoomHandler, EliteRoomHandler, BossRoomHandler）

**测试结果**: 所有测试通过（6/6套件），历史记录功能正常

**已知问题修复**:
- ✅ 修复冒险模式战斗记录不保存的问题：
  - 原因：`BattleRoomHandler`、`EliteRoomHandler`、`BossRoomHandler` 缺少战斗记录保存逻辑
  - 解决：在 `RoomContext` 添加 `historyService` 字段，所有战斗处理器在战斗结束后调用 `BattleRecordBuilder.build()` 并保存记录
  - 验证：测试完成后历史记录和统计数据正确显示

---
- [ ] 主菜单存在“继续上次冒险”（无存档时行为明确：隐藏/置灰/提示）
- [ ] 节点完成后会自动保存（退出重进仍保持 map/deck/hp/进度）
- [ ] 存档版本不匹配有明确提示，不会崩溃

---

## 📝 修订历史

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-01-03 | v1.0 | 初稿 |
| 2026-01-03 | v1.1 | 审视并修复设计问题：|
| | | - 添加 `DamageCalculator`（P1） |
| | | - 修复 P1/P2 之间的状态类型依赖：P1 使用强类型 `StatusID`，P2 由 `StatusRegistry` 提供显示与行为 |
| | | - 添加卡牌升级系统支持 |
| | | - 明确 `StatusContainer` 与 Entity 集成方式 |
| | | - 移除 P4 房间系统协议化（不必要） |
| | | - 完善遗物系统设计 |
| | | - 添加详细检查清单 |
