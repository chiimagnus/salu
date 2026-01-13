# GameCore 模块开发规范

> 设定/剧情/玩法规则文档优先对齐 `.codex/docs/`。

## 模块定位

GameCore 是**纯逻辑层**：负责规则、状态、决策、确定性随机、快照模型。

关键目标：

- **可复现**：同 seed + 同输入 → 结果一致（战斗/地图/奖励/事件/商店）。
- **可测试**：逻辑可在 `GameCoreTests` 里稳定断言。
- **可扩展**：新增内容优先走 `Definition + Registry`，尽量不改引擎。

当前目录结构（以实际代码为准）：

```
Sources/GameCore/  ← 本规范适用范围
│
├── Kernel/                 # 强类型 ID / Effect / Trigger 框架
├── Entity/                 # Entity（玩家/敌人统一实体）
├── Battle/                 # BattleEngine / BattleState / Damage&BlockCalculator
├── Cards/                  # CardDefinition / CardRegistry / StarterDeck
├── Status/                 # StatusDefinition / StatusRegistry / StatusContainer
├── Enemies/                # EnemyDefinition / EnemyRegistry / EnemyPool / EncounterPool
├── Relics/                 # RelicDefinition / RelicRegistry / RelicManager / RelicPool
├── Consumables/            # ConsumableDefinition / ConsumableRegistry
├── Events/                 # EventDefinition / EventRegistry / EventGenerator
├── Rewards/                # RewardGenerator / GoldRewardStrategy / CardPool
├── Shop/                   # ShopInventory / ShopPricing / ShopContext
├── Map/                    # MapNode / MapGenerator / RoomType
├── Run/                    # RunState / RunSnapshot / RunEffect / RunSaveVersion
├── Persistence/            # BattleHistoryStore / RunSaveStore（协议，仅定义接口）
│
├── Actions.swift           # 玩家动作定义（输入层可用）
├── Events.swift            # 战斗事件定义（BattleEvent）
├── History.swift           # 战绩数据模型（BattleRecord 等，允许 Foundation）
└── RNG.swift               # SeededRNG（可复现 RNG）
```

---

## 核心架构：Definition + Registry + Effect

GameCore 的内容扩展点遵循“协议驱动开发（PDD）”思路：

- **强类型 ID**：`CardID/StatusID/EnemyID/RelicID/EventID/ConsumableID`（禁止散落字符串）。
- **定义协议（只决策）**：
  - `CardDefinition`：`play(snapshot:targetEnemyIndex:) -> [BattleEffect]`
  - `StatusDefinition`：修正（phase+priority）与回合末触发（`onTurnEnd`）
  - `EnemyDefinition`：`chooseMove(selfIndex:snapshot:rng:) -> EnemyMove`
  - `RelicDefinition`：`onBattleTrigger(_:snapshot:) -> [BattleEffect]`
  - `EventDefinition`：`generate(context:rng:) -> EventOffer`
  - `ConsumableDefinition`：产生效果/修改 RunState（取决于具体协议定义）
- **注册表（唯一入口）**：`CardRegistry/StatusRegistry/EnemyRegistry/RelicRegistry/EventRegistry/ConsumableRegistry`。
- **统一效果管线**：所有战斗内影响统一由 `BattleEffect` 描述，只有 `BattleEngine` 执行效果并发出 `BattleEvent`。

约束：新增卡牌/状态/敌人/遗物/事件/消耗品时，尽量只做“新增 Definition + 在 Registry 注册”，避免在 `BattleEngine` 里新增 `switch` 扩展点。

---

## 多敌人战斗 + 显式目标

多敌人已接入，新增内容时必须遵守：

- **目标模型**：统一使用 `EffectTarget`
  - 玩家：`.player`
  - 敌人实例：`.enemy(index: Int)`（索引对应 `BattleState.enemies`）
- **玩家动作**：`PlayerAction.playCard(handIndex:targetEnemyIndex:)`
  - 需要目标的牌必须提供 `targetEnemyIndex`
  - 目标合法性由 `BattleEngine` 校验并通过 `BattleEvent.invalidAction` 反馈
- **卡牌定义**：`CardDefinition.play(snapshot:targetEnemyIndex:)`
  - 不要把敌人索引写死为 0
  - 生成效果时用 `.enemy(index: targetEnemyIndex)`
- **敌人 AI**：`EnemyDefinition.chooseMove(selfIndex:snapshot:rng:)`
  - 对“自己”施加效果时使用 `selfIndex`

---

## 可复现性（Determinism）规范

### 统一 RNG

- GameCore 内随机必须来自 `SeededRNG`（见 `RNG.swift`）。
- 推荐签名形态：`func foo(..., rng: inout SeededRNG)`，并在需要时由调用方派生 seed 或传入同一个 rng。

严格禁止：

- ❌ `Int.random(...)`、`SystemRandomNumberGenerator`、`array.shuffled()`（无 rng 参数）
- ❌ 依赖系统时间作为随机源（例如 `Date()` 参与决策）

### 派生 seed（地图/奖励/事件/商店）

对“非战斗引擎内部”的生成器（例如事件/奖励/商店），目前采用**派生 seed + salt** 的方式保证稳定性：

- 同 `seed + floor + row + nodeId (+ roomType)` → 结果稳定
- 不同系统使用不同 salt，避免强相关（例如事件 vs 奖励）
- Hash 计算必须是纯 Swift（当前使用 FNV-1a 64）

已有实现可参考：`Events/EventGenerator`、`Rewards/RewardGenerator`、`Rewards/GoldRewardStrategy`、`Shop/ShopInventory`。

### Date/UUID 的使用边界

- `History.swift` 允许 `Foundation`，并使用 `Date/UUID` 作为默认值来生成**记录 ID/时间戳**。
- 但在**核心决策/战斗/地图/奖励**里禁止隐式引入 `Date/UUID`：需要时间/ID 时必须由外部注入。

---

## 并发与 Sendable

- 需要跨模块（GameCLI → GameCore）访问的类型应为 `public`。
- `Sendable` 是默认要求：值类型优先；引用类型如必须出现，应显式标注并解释并发语义。

注意：

- `BattleEngine` 与 `SeededRNG` 当前为 `@unchecked Sendable`，并不意味着线程安全。
  - 约束：它们应当被当作“单线程/单任务”对象使用；不要在多个并发任务中共享同一个实例。

---

## I/O 与依赖边界

### 严格禁止

- ❌ `print()` 或任何控制台输出
- ❌ 读取 `stdin` 或任何用户输入
- ❌ 文件系统/网络/环境变量读取（这些属于 GameCLI 层）
- ❌ 导入任何 UI 框架
- ❌ 反向依赖 GameCLI
- ❌ 导入 `Foundation`
  - ✅ 唯一例外：`History.swift`（战绩模型需要 `Date/UUID`）

### 持久化

- GameCore 只定义协议：`Persistence/BattleHistoryStore`、`Persistence/RunSaveStore`
- 实际落盘/JSON 编解码/目录结构属于 GameCLI（实现这些协议）

---

## 设计与代码组织

### 单一职责（SRP）

- Definition 文件：只做“决策/产出”，不直接改 `BattleState`，不直接 emit 事件。
- Engine 文件：只做“执行效果 + 产生事件 + 驱动流程”。

### 依赖方向（推荐）

```
Battle/BattleEngine.swift
    ↓ 使用
┌──────────────────────────────────────────────────────────────┐
│ Kernel/*  Entity/*  Cards/*  Status/*  Enemies/*  Relics/*   │
│ Consumables/*  Events/*  Rewards/*  Shop/*  Map/*  Run/*     │
└──────────────────────────────────────────────────────────────┘
    ↓ 使用
┌──────────────────────────────────────────┐
│ RNG.swift                                  │
└──────────────────────────────────────────┘
```

---

## 扩展指南（按领域）

### 添加新卡牌

1. 在 `Cards/Definitions/**` 新增一个实现 `CardDefinition` 的类型。
2. `play(snapshot:targetEnemyIndex:)` 只返回 `[BattleEffect]`，不要直接改状态/emit 事件。
3. 需要目标时：
   - `targeting = .singleEnemy`
   - 生成效果时使用 `.enemy(index: targetEnemyIndex)`
4. 在 `Cards/CardRegistry.swift` 注册 `CardID -> Definition`。
5. 奖励池：若该牌可作为奖励出现，确认 `Rewards/CardPool` 的规则能覆盖（避免把起始牌/剧情牌误放入奖励池）。

### 添加状态（Buff/Debuff）

1. 在 `Status/Definitions/**` 新增实现 `StatusDefinition` 的类型。
2. 修正型效果使用 phase + priority：
   - `outgoingDamagePhase / incomingDamagePhase / blockPhase`
   - `priority` 用于稳定顺序（越小越先应用）
   - 具体修正写在 `modifyOutgoingDamage/modifyIncomingDamage/modifyBlock`
3. 触发型（如中毒）使用：`onTurnEnd(owner:stacks:snapshot:) -> [BattleEffect]`。
4. 递减规则：通过 `decay` 声明（例如 `.turnEnd(decreaseBy: 1)`）。
5. 在 `Status/StatusRegistry.swift` 注册。

说明：伤害/格挡修正的执行顺序由 `Battle/DamageCalculator.swift`、`Battle/DamageCalculator.swift` 的 `BlockCalculator` 按 **ModifierPhase + priority** 确定性应用。

### 添加新敌人

1. 在 `Enemies/Definitions/Act*/**` 新增实现 `EnemyDefinition` 的类型。
2. AI 必须只通过返回 `EnemyMove` 来描述意图与效果：
   - 随机只能来自 `rng`（inout），且随机结果必须固化进 `EnemyMove.effects`
3. `chooseMove(selfIndex:snapshot:rng:)` 中：
   - 对自己施加效果用 `.enemy(index: selfIndex)`
4. 在 `Enemies/EnemyRegistry.swift` 注册，并根据需要把敌人加入 `EnemyPool/EncounterPool`。

### 添加新遗物

1. 在 `Relics/Definitions/**` 新增实现 `RelicDefinition` 的类型。
2. 仅通过 `onBattleTrigger(_:snapshot:)` 产出 `[BattleEffect]`。
3. 在 `Relics/RelicRegistry.swift` 注册，并根据需要更新 `RelicPool/RelicDropStrategy`。

### 添加新消耗品

1. 在 `Consumables/Definitions/**` 新增实现 `ConsumableDefinition` 的类型。
2. 在 `Consumables/ConsumableRegistry.swift` 注册。
3. 若要进入商店，确认其 ID 出现在 `ConsumableRegistry.shopConsumableIds`（或对应选择逻辑）。

### 添加新地图事件

1. 在 `Events/Definitions/**` 新增实现 `EventDefinition` 的类型。
2. `generate(context:rng:)` 必须只做决策与产出：返回 `EventOffer`（选项、后续、效果）。
3. 随机只能来自注入的 `rng`。
4. 在 `Events/EventRegistry.swift` 注册。

---

## 命名与文件约束

- 类型：`UpperCamelCase`
- 成员/方法：`lowerCamelCase`
- 文件名：与主类型同名或按领域清晰命名
- SwiftPM 限制：同一 target 内源文件 basename 必须唯一（避免 `multiple producers`）
  - 按 Act 拆分同类定义文件时必须带前缀：`Act1BossEnemies.swift` / `Act2BossEnemies.swift` 等

---

## 检查清单

- [ ] GameCore 内无 `print()`、无任何 I/O（文件/网络/环境变量）
- [ ] 除 `History.swift` 外无 `import Foundation`
- [ ] 随机全部使用 `SeededRNG`（或派生 seed + salt），无系统随机
- [ ] Definition 层只产出效果/选项，不直接改状态、不直接 emit 事件
- [ ] 多敌人相关：未把敌人索引写死为 0
- [ ] 新增内容已在对应 Registry 注册，并补充或更新 `GameCoreTests` 的覆盖
