# Salu 1.0 占卜家序列 —— 详细实现计划

> 本文档基于对现有代码库的深入分析，为每个优先级提供具体的实现步骤。
> 设计草案：已整合到 `.cursor/rules/Salu游戏设定与剧情v1.0.mdc` 第 6 章"占卜家序列流派设计"

---

## 代码架构总结

通过阅读代码，确认以下关键架构点：

### 状态系统（Status）
- **位置**：`Sources/GameCore/Status/`
- **核心协议**：`StatusDefinition`（支持修正型和触发型两种）
- **注册表**：`StatusRegistry`（静态字典，新增状态需在此注册）
- **容器**：`StatusContainer`（纯数据，存储 `[StatusID: Int]`）
- **现有状态**：Vulnerable、Weak、Frail、Poison（Debuff）+ Strength、Dexterity（Buff）
- **递减规则**：`StatusDecay`（`.none` 或 `.turnEnd(decreaseBy:)`）
- **触发点**：`onTurnEnd(owner:stacks:snapshot:) -> [BattleEffect]`

### 战斗系统（Battle）
- **位置**：`Sources/GameCore/Battle/`
- **引擎**：`BattleEngine`（状态机，处理回合/出牌/敌人行动）
- **状态**：`BattleState`（玩家/敌人/能量/牌堆/回合数）
- **效果管线**：`BattleEffect`（统一效果枚举，由 `apply(_:)` 执行）
- **事件输出**：`BattleEvent`（所有状态变化通过 `emit(_:)` 记录）
- **遗物触发**：`triggerRelics(_:)`（在关键时机调用 `RelicManager`）

### 敌人系统（Enemies）
- **位置**：`Sources/GameCore/Enemies/`
- **定义协议**：`EnemyDefinition`（AI 选择行动）
- **行动模型**：`EnemyMove`（`intent: EnemyIntentDisplay` + `effects: [BattleEffect]`）
- **意图展示**：`EnemyIntentDisplay`（`icon`/`text`/`previewDamage`）
- **注册表**：`EnemyRegistry`

### 卡牌系统（Cards）
- **位置**：`Sources/GameCore/Cards/`
- **定义协议**：`CardDefinition`（`play(snapshot:targetEnemyIndex:) -> [BattleEffect]`）
- **目标类型**：`CardTargeting`（`.none` / `.singleEnemy`）
- **注册表**：`CardRegistry`

### 遗物系统（Relics）
- **位置**：`Sources/GameCore/Relics/`
- **定义协议**：`RelicDefinition`（`onBattleTrigger(_:snapshot:) -> [BattleEffect]`）
- **触发点**：`BattleTrigger`（battleStart/End、turnStart/End、cardPlayed 等）
- **注册表**：`RelicRegistry`

### 商店系统（Shop）
- **位置**：`Sources/GameCore/Shop/`
- **库存模型**：`ShopInventory`（P4：`cardOffers` + `relicOffers` + `consumableOffers` + `removeCardPrice`）
- **条目类型**：`ShopItem.Kind`（P4：`.card` / `.relic` / `.consumable` / `.removeCard`）
- **定价**：`ShopPricing`（P4：新增遗物/消耗品定价）

### 消耗品系统（Consumables）
- **位置**：`Sources/GameCore/Consumables/`
- **核心协议**：`ConsumableDefinition`
- **注册表**：`ConsumableRegistry`
- **Run 持有**：`RunState.consumables`（上限 3 个槽位）

### 事件系统（Events）
- **位置**：`Sources/GameCore/Events/`
- **定义协议**：`EventDefinition`（`generate(context:rng:) -> EventOffer`）
- **选项模型**：`EventOption`（`title`/`preview`/`effects: [RunEffect]`/`followUp`）
- **Run效果**：`RunEffect`（gainGold/heal/addCard/addRelic/upgradeCard 等）

---

## P0：疯狂状态系统 ✅ 已完成

> 完成日期：2026-01-11
> 包含：Madness 状态定义、阈值检查、回合结束消减、界面显示

### P0-1：新增 MadnessStatus 状态定义

**文件**：`Sources/GameCore/Status/Definitions/Debuffs.swift`（新增在文件末尾）

**实现步骤**：
1. 在 `Debuffs.swift` 末尾添加 `Madness` 结构体
2. 实现 `StatusDefinition` 协议
3. 疯狂不递减（`.none`），由专门逻辑处理

```swift
// ============================================================
// Madness (疯狂)
// ============================================================

/// 疯狂：占卜家使用强力能力的代价
/// - 阈值 3：回合开始随机弃 1 张牌
/// - 阈值 6：回合开始获得虚弱 1
/// - 阈值 10：受到伤害 +50%
public struct Madness: StatusDefinition {
    public static let id: StatusID = "madness"
    public static let name = "疯狂"
    public static let icon = "🌀"
    public static let isPositive = false
    public static let decay: StatusDecay = .none  // 疯狂不自动递减，由回合结束 -1 处理
    
    // 疯狂不参与修正（阈值检查由 BattleEngine 专门处理）
}
```

**注意**：疯狂的"受到伤害 +50%"阈值效果需要在 P0-2 中实现，因为它涉及到修正计算时的阈值检查。

### P0-2：在 StatusRegistry 注册

**文件**：`Sources/GameCore/Status/StatusRegistry.swift`

**修改**：在 `defs` 字典中添加：
```swift
Madness.id: Madness.self,
```

### P0-3：实现疯狂阈值触发逻辑

**文件**：`Sources/GameCore/Battle/BattleEngine.swift`

**实现步骤**：

1. 在 `startNewTurn()` 中添加疯狂阈值检查（在清除格挡后、抽牌前）：

```swift
// 疯狂阈值检查（P0：占卜家序列）
checkMadnessThresholds()
```

2. 添加私有方法 `checkMadnessThresholds()`：

```swift
/// 检查玩家疯狂阈值并触发效果
private func checkMadnessThresholds() {
    let madnessStacks = state.player.statuses.stacks(of: Madness.id)
    guard madnessStacks > 0 else { return }
    
    // 阈值 1（3 层）：随机弃 1 张牌
    if madnessStacks >= 3 && !state.hand.isEmpty {
        let discardIndex = rng.next(upperBound: UInt64(state.hand.count))
        let discardedCard = state.hand.remove(at: Int(discardIndex))
        state.discardPile.append(discardedCard)
        emit(.madnessDiscard(cardId: discardedCard.cardId))
    }
    
    // 阈值 2（6 层）：获得虚弱 1
    if madnessStacks >= 6 {
        applyStatusEffect(target: .player, statusId: Weak.id, stacks: 1)
        emit(.madnessThreshold(level: 2, effect: "虚弱 1"))
    }
    
    // 阈值 3（10 层）的"受到伤害 +50%"需要在伤害计算时检查
}
```

3. 在 `DamageCalculator.swift` 中支持疯狂阈值 3 的伤害增加（或直接在 `applyDamage` 中检查）

**替代方案**：让 `Madness` 实现 `incomingDamagePhase = .multiply` 并在 `modifyIncomingDamage` 中检查层数 >= 10：

```swift
public static let incomingDamagePhase: ModifierPhase? = .multiply
public static let priority = 200  // 在易伤之后应用

public static func modifyIncomingDamage(_ value: Int, stacks: Int) -> Int {
    // 阈值 3（10 层）：受到伤害 +50%
    if stacks >= 10 {
        return Int(Double(value) * 1.5)
    }
    return value
}
```

### P0-4：实现回合结束疯狂 -1 消减

**文件**：`Sources/GameCore/Battle/BattleEngine.swift`

**实现步骤**：

在 `endPlayerTurn()` 中，`processStatusesAtTurnEnd(for: .player)` 之后添加：

```swift
// 疯狂消减（P0：占卜家序列）
reduceMadness()
```

添加私有方法：

```swift
/// 回合结束时疯狂 -1
private func reduceMadness() {
    let currentMadness = state.player.statuses.stacks(of: Madness.id)
    if currentMadness > 0 {
        state.player.statuses.apply(Madness.id, stacks: -1)
        let newMadness = state.player.statuses.stacks(of: Madness.id)
        emit(.madnessReduced(from: currentMadness, to: newMadness))
    }
}
```

### P0-5：更新 BattleEvent 支持疯狂事件

**文件**：`Sources/GameCore/Events.swift`

**新增事件类型**：

```swift
/// 疯狂变化
case madnessChanged(target: String, stacks: Int, total: Int)

/// 疯狂消减
case madnessReduced(from: Int, to: Int)

/// 疯狂阈值触发
case madnessThreshold(level: Int, effect: String)

/// 疯狂导致弃牌
case madnessDiscard(cardId: CardID)
```

**更新 `description` 扩展**。

### P0-6：更新战斗界面显示疯狂

**文件**：`Sources/GameCLI/Screens/BattleScreen.swift`

**实现步骤**：

1. 在玩家状态区域显示疯狂层数
2. 疯狂 >= 3 时用黄色显示
3. 疯狂 >= 6 时用橙色显示
4. 疯狂 >= 10 时用红色显示

### P0 验收

```bash
swift build
swift test
SALU_TEST_MODE=1 SALU_TEST_MAP=battle swift run GameCLI --seed 1
```

---

## P1：核心卡牌机制 ✅ 已完成

> 完成日期：2026-01-11
> 包含：
> - BattleEffect: foresight / rewind / clearMadness
> - BattleEvent: foresightChosen / rewindCard / madnessCleared
> - 占卜家卡牌：灵视/灵视+、真相低语/真相低语+、冥想/冥想+、理智燃烧/理智燃烧+
> - 文件：Sources/GameCore/Cards/Definitions/Seer/SeerCards.swift

### P1-1：实现"预知"关键词机制

**设计**：
- 预知 N = 查看抽牌堆顶 N 张，选 1 张入手，其余原顺序放回
- 由于 CLI 需要玩家交互选择，分为两步：
  1. `BattleEngine` 提供 `startForesight(count:) -> [Card]`（返回顶部 N 张）
  2. `BattleEngine` 提供 `completeForesight(chosenIndex:)`（玩家选择后调用）

**替代方案（简化版，推荐 1.0 使用）**：
- 预知 N = 查看抽牌堆顶 N 张，自动选择第一张攻击牌入手，其余放回
- 如果没有攻击牌，选择第一张

**文件改动**：
1. `Sources/GameCore/Kernel/BattleEffect.swift`：新增 `.foresight(count: Int)`
2. `Sources/GameCore/Battle/BattleEngine.swift`：在 `apply(_:)` 中处理 `.foresight`

```swift
case .foresight(let count):
    applyForesight(count: count)
```

```swift
/// 应用预知效果（简化版：自动选择第一张攻击牌）
private func applyForesight(count: Int) {
    guard count > 0, !state.drawPile.isEmpty else { return }
    
    // 取出顶部 count 张（注意 drawPile 是 LIFO，末尾是顶部）
    let actualCount = min(count, state.drawPile.count)
    let topCards = Array(state.drawPile.suffix(actualCount).reversed())
    state.drawPile.removeLast(actualCount)
    
    // 选择第一张攻击牌（简化逻辑）
    var chosenIndex = 0
    for (index, card) in topCards.enumerated() {
        let def = CardRegistry.require(card.cardId)
        if def.type == .attack {
            chosenIndex = index
            break
        }
    }
    
    // 选中的牌入手
    let chosenCard = topCards[chosenIndex]
    state.hand.append(chosenCard)
    emit(.foresightChosen(cardId: chosenCard.cardId, fromCount: actualCount))
    
    // 其余牌按原顺序放回（顶部在 drawPile 末尾）
    for (index, card) in topCards.enumerated().reversed() {
        if index != chosenIndex {
            state.drawPile.append(card)
        }
    }
}
```

3. `Sources/GameCore/Events.swift`：新增事件

```swift
/// 预知选择
case foresightChosen(cardId: CardID, fromCount: Int)
```

### P1-2：实现"回溯"关键词机制

**设计**：
- 回溯 N = 从弃牌堆选 N 张牌返回手牌
- 简化版：自动选择最近弃置的 N 张

**文件改动**：
1. `Sources/GameCore/Kernel/BattleEffect.swift`：新增 `.rewind(count: Int)`
2. `Sources/GameCore/Battle/BattleEngine.swift`：

```swift
case .rewind(let count):
    applyRewind(count: count)
```

```swift
/// 应用回溯效果
private func applyRewind(count: Int) {
    guard count > 0, !state.discardPile.isEmpty else { return }
    
    let actualCount = min(count, state.discardPile.count)
    for _ in 0..<actualCount {
        let card = state.discardPile.removeLast()
        state.hand.append(card)
        emit(.rewindCard(cardId: card.cardId))
    }
}
```

3. `Sources/GameCore/Events.swift`：

```swift
/// 回溯卡牌
case rewindCard(cardId: CardID)
```

### P1-3：实现"改写"关键词机制

**设计**：
- 改写 = 将目标敌人的本回合意图替换为指定类型
- 需要扩展 `EnemyMove` 或在 `Entity` 中添加标记

**文件改动**：

1. `Sources/GameCore/Kernel/BattleEffect.swift`：

```swift
/// 改写敌人意图
case rewriteIntent(enemyIndex: Int, newIntent: RewrittenIntent)
```

2. 新增 `Sources/GameCore/Enemies/RewrittenIntent.swift`：

```swift
/// 改写后的意图类型
public enum RewrittenIntent: Sendable, Equatable {
    case defend(block: Int)  // 改为防御
    case skip               // 跳过行动
}
```

3. `Sources/GameCore/Battle/BattleEngine.swift`：

```swift
case .rewriteIntent(let enemyIndex, let newIntent):
    applyRewriteIntent(enemyIndex: enemyIndex, newIntent: newIntent)
```

```swift
/// 应用改写意图
private func applyRewriteIntent(enemyIndex: Int, newIntent: RewrittenIntent) {
    guard enemyIndex >= 0, enemyIndex < state.enemies.count else { return }
    guard state.enemies[enemyIndex].isAlive else { return }
    
    let oldMove = state.enemies[enemyIndex].plannedMove
    
    let newMove: EnemyMove
    switch newIntent {
    case .defend(let block):
        newMove = EnemyMove(
            intent: EnemyIntentDisplay(icon: "🛡️", text: "防御（被改写）"),
            effects: [.gainBlock(target: .enemy(index: enemyIndex), base: block)]
        )
    case .skip:
        newMove = EnemyMove(
            intent: EnemyIntentDisplay(icon: "💫", text: "眩晕（被改写）"),
            effects: []
        )
    }
    
    state.enemies[enemyIndex].plannedMove = newMove
    emit(.intentRewritten(
        enemyName: state.enemies[enemyIndex].name,
        oldIntent: oldMove?.intent.text ?? "未知",
        newIntent: newMove.intent.text
    ))
}
```

4. `Sources/GameCore/Events.swift`：

```swift
/// 意图被改写
case intentRewritten(enemyName: String, oldIntent: String, newIntent: String)
```

### P1-4~7：新增占卜家卡牌

**文件**：新建 `Sources/GameCore/Cards/Definitions/SeerCards.swift`

实现 10 张卡牌定义，参考设计文档。

**注册**：在 `CardRegistry.swift` 的 `defs` 中添加所有新卡牌。

### P1 验收

```bash
swift build
swift test
```

---

## P2：敌人意图扩展 ✅ 已完成

> 完成日期：2026-01-11
> 包含：精神冲击意图、疯狂预言者、时间守卫、赛弗 Boss

### P2-1：扩展意图类型

由于 `EnemyIntentDisplay` 只是展示用，实际效果由 `EnemyMove.effects` 决定，所以只需要：

1. 在敌人定义中使用新的意图图标和文本
2. 配合对应的 `BattleEffect` 列表

### P2-2~3：精神冲击意图

精神冲击 = 伤害 + 给予玩家疯狂

```swift
// 在敌人 chooseMove 中
EnemyMove(
    intent: EnemyIntentDisplay(icon: "👁️", text: "精神冲击", previewDamage: 8),
    effects: [
        .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 8),
        .applyStatus(target: .player, statusId: Madness.id, stacks: 2)
    ]
)
```

### P2-4~6：新精英和 Boss

见设计文档。

---

## P3：占卜家遗物扩展 ✅ 已完成

> 完成日期：2026-01-11
> 包含：6 个占卜家专属遗物

### P3-1~2：战斗开始触发遗物

**文件**：`Sources/GameCore/Relics/Definitions/SeerRelics.swift`（新建）

实现以下遗物：
- **第三只眼**：战斗开始时预知 2
- **深渊之瞳**：战斗开始时预知 3，+1 疯狂

### P3-3：理智之锚（阈值修改）

**文件**：`Sources/GameCore/Battle/BattleEngine.swift`

在 `checkMadnessThresholds()` 中检查玩家是否拥有理智之锚遗物，如果有则所有阈值 +3。

### P3-4：疯狂面具（伤害修正）

**文件**：`Sources/GameCore/Battle/BattleEngine.swift`

在 `calculateDamage()` 中检查攻击者是否为玩家且拥有疯狂面具遗物，如果疯狂 ≥6 则攻击伤害 +50%。

### P3-5：破碎怀表（预知增强）

**文件**：`Sources/GameCore/Battle/BattleEngine.swift`

添加 `foresightUsedThisTurn` 追踪变量，在 `applyForesight()` 中检查首次预知时是否拥有破碎怀表，如果有则额外预知 1 张。

### P3-6：预言者手札（改写免疫）

**文件**：`Sources/GameCore/Battle/BattleEngine.swift`

添加 `rewriteUsedThisBattle` 和 `shouldSkipNextMadnessFromRewrite` 追踪变量：
- 在 `applyRewriteIntent()` 中检查首次改写时是否拥有预言者手札
- 在 `applyStatusEffect()` 中检查是否应跳过疯狂添加

### P3-7：注册遗物

**文件**：`Sources/GameCore/Relics/RelicRegistry.swift`

注册 6 个新遗物到注册表。

---

## P4：商店扩展（12 格 + 消耗品系统）✅ 已完成

> 完成日期：2026-01-11
> 包含：5 张卡牌 + 3 个遗物 + 3 个消耗品 + 1 个删牌服务；新增消耗品系统并接入存档。

### P4-1：新增消耗品系统（GameCore）

**新增目录**：`Sources/GameCore/Consumables/`

**新增文件**：
- `ConsumableDefinition.swift`：定义 `ConsumableID` / `ConsumableRarity` / `ConsumableDefinition`
- `ConsumableRegistry.swift`：注册表
- `Definitions/CommonConsumables.swift`：通用消耗品（治疗/格挡/力量）
- `Definitions/SeerConsumables.swift`：占卜家消耗品（净化符文：清除所有疯狂）

### P4-2：扩展 RunState 持有消耗品 + 槽位限制

**文件**：`Sources/GameCore/Run/RunState.swift`

**新增**：
- `consumables: [ConsumableID]`（最多 `maxConsumableSlots = 3`）
- `addConsumable(_:) -> Bool` / `removeConsumable(at:)`

### P4-3：扩展存档快照（破坏性变更）

**文件**：
- `Sources/GameCore/Run/RunSaveVersion.swift`：版本升到 `3`（不兼容旧版本）
- `Sources/GameCore/Run/RunSnapshot.swift`：新增 `consumableIds`
- `Sources/GameCLI/Persistence/SaveService.swift`：create/restore 读写 `consumableIds`

**测试更新**：
- `Tests/GameCoreTests/RunSnapshotCodableTests.swift`
- `Tests/GameCLITests/SaveServiceTests.swift`

### P4-4：扩展 Shop 模型（GameCore）

**文件**：
- `Sources/GameCore/Shop/ShopItem.swift`：新增 `.relic/.consumable` 报价类型与展示辅助
- `Sources/GameCore/Shop/ShopInventory.swift`：生成 5/3/3 + 删牌
- `Sources/GameCore/Shop/ShopContext.swift`：新增 `ownedRelicIds`（过滤已拥有遗物）
- `Sources/GameCore/Shop/ShopPricing.swift`：新增遗物/消耗品定价

**测试更新**：
- `Tests/GameCoreTests/ShopInventoryTests.swift`

### P4-5：更新 CLI 商店交互（GameCLI）

**文件**：
- `Sources/GameCLI/Screens/ShopScreen.swift`：显示卡牌/遗物/消耗品三栏 + 删牌
- `Sources/GameCLI/Rooms/Handlers/ShopRoomHandler.swift`
  - 新输入：`R1..R3` 买遗物，`C1..C3` 买消耗品
  - 消耗品槽位满时阻止购买

### P4 验收

```bash
swift build
swift test
SALU_TEST_MODE=1 SALU_TEST_MAP=shop swift run GameCLI --seed 1
```

---

## P5：事件扩展（占卜家专属事件）✅ 已实现

### 目标
- 把设计文档中的占卜家事件落地到 `GameCore/Events`，并接入 CLI 的事件房间流程。
- 覆盖：新增卡牌/遗物/疯狂变化/升级卡牌（二次选择）。

### 需要实现的事件（v1.0）
- **序列密室**：获得卡牌“命运改写”并 +3 疯狂 / 清除 3 疯狂但失去 10 HP / 离开
- **时间裂隙**：升级 1 张卡牌（follow-up 选择）并 +2 疯狂 / 获得遗物“破碎怀表”并 +2 疯狂 / 回复 10 HP
- **疯狂预言者**（可选拓展）：听预言得稀有卡并 +4 疯狂 / 进入精英战 / 给钱回复并清除疯狂

### 实现步骤（可执行）
#### P5-0 现状确认（已存在能力）
- `EventFollowUp` 已支持：`chooseUpgradeableCard(indices:)` + `startEliteBattle(enemyId:)`
- `EventRoomHandler` 已支持二次选择流程（升级卡牌）

#### P5-1 扩展 RunEffect（为“疯狂变化 / 获得消耗品”提供落点）
**目标**：让事件可以在**战斗外**对 RunState 的玩家状态做修改（例如 +3 疯狂、清除 3 疯狂），并允许事件奖励消耗品。

**文件**：
- `Sources/GameCore/Run/RunEffect.swift`
- `Sources/GameCore/Run/RunState.swift`
- `Sources/GameCLI/Rooms/Handlers/EventRoomHandler.swift`（result 文本摘要）

**新增 RunEffect 建议**（全部为破坏性变更策略，不做向后兼容）：  
- `case applyStatus(statusId: StatusID, stacks: Int)`（可正可负；用于 +疯狂 / 清除疯狂）  
- `case setStatus(statusId: StatusID, stacks: Int)`（用于“清除所有疯狂”等）  
- `case addConsumable(consumableId: ConsumableID)`（用于事件奖励消耗品）  

**RunState.apply(effect:)** 需要新增分支：  
- `applyStatus/setStatus`：直接对 `runState.player.statuses` 做 apply / set  
- `addConsumable`：调用 `runState.addConsumable`，若满槽则返回 false（事件层可根据返回值决定展示文案）  

**EventRoomHandler.buildResultLines** 需要补齐上述新 case 的文本摘要。

#### P5-2 新增占卜家事件定义文件
**新增文件**：`Sources/GameCore/Events/Definitions/SeerEvents.swift`

**事件 A：序列密室（seer_sequence_chamber）**
- 选项 1：阅读禁书 → `addCard(fate_rewrite)` + `applyStatus(madness,+3)`
- 选项 2：焚毁书页 → `takeDamage(10)` + `applyStatus(madness,-3)`
- 选项 3：离开 → 无效果

**事件 B：时间裂隙（seer_time_rift）**
- 选项 1：窥视过去 → `applyStatus(madness,+2)` + followUp：`chooseUpgradeableCard(indices: runState.upgradeableCardIndices)`
- 选项 2：窥视未来 → `addRelic(broken_watch)` + `applyStatus(madness,+2)`
- 选项 3：闭眼离开 → `heal(10)`

**事件 C：疯狂预言者（seer_mad_prophet）**
- 选项 1：聆听预言 → `addCard(abyssal_gaze)` + `applyStatus(madness,+4)`
- 选项 2：打断他 → followUp：`startEliteBattle(enemyId: mad_prophet)`（事件内进入精英战链路）  
- 选项 3：给予金币安抚 → `loseGold(30)` + `heal(15)` + `applyStatus(madness,-2)`

> **确定性要求**：事件只用 `EventContext` + `rng` 决定“出现哪个事件/选项效果”，不要在 EventDefinition 里做 I/O。

#### P5-3 注册事件
**文件**：`Sources/GameCore/Events/EventRegistry.swift`  
把新事件加入 `defs`。

#### P5-4 CLI 事件 UI 与日志（已有能力，补齐文案即可）
**文件**：`Sources/GameCLI/Screens/EventScreen.swift`、`Sources/GameCLI/Rooms/Handlers/EventRoomHandler.swift`
- 事件展示/选项输入/升级 follow-up 已存在  
- 只需要保证新增 RunEffect 的摘要文案可读、为中文

#### P5-5 测试（必须新增）
**新增测试文件**：`Tests/GameCoreTests/SeerEventDefinitionsTests.swift`
- 验证每个事件 `generate` 的 options 数量、effects 内容、followUp 合法性（indices 在牌组范围内）

**更新/补充现有测试**：
- `Tests/GameCoreTests/EventGeneratorTests.swift`：确保 `EventRegistry` 扩容后仍 determinism

**UI 验收测试**（黑盒，可后置但建议接入）：
- 新增 `Tests/GameCLIUITests/GameCLISeerEventUITests.swift`（或扩展现有事件 UI 测试）
- 使用 `SALU_TEST_MODE=1 SALU_TEST_MAP=event`

### P5 验收
```bash
swift build
swift test
SALU_TEST_MODE=1 SALU_TEST_MAP=event swift run GameCLI --seed 1
```

---

## P6：赛弗 Boss 特殊机制 ✅ 已完成

> 完成日期：2026-01-12
> 包含：预知反制/命运剥夺/命运改写/时间回溯 + 单元测试（`CipherBossMechanicsTests`）

### 目标
实现设计文档中赛弗的“反制/剥夺/改写/回溯”特色机制，强化“改写”卡牌的战略价值。

### 实现路径（建议）
#### P6-1 新增“赛弗专属效果”承载方式（推荐：BattleEffect + BattleEngine 临时状态）

> 目标：不引入复杂的新系统（例如完整的“意图改写反制栈”），但能表达赛弗的 4 个核心机制。

**建议新增 BattleEffect（最小集合）**：
- `case applyForesightPenaltyNextTurn(amount: Int)`：下回合预知数量 -amount（最低 0）
- `case applyFirstCardCostIncreaseNextTurn(amount: Int)`：下回合第一张牌费用 +amount
- `case discardRandomHand(count: Int)`：随机弃置 count 张手牌（用于命运剥夺）
- `case enemyHeal(enemyIndex: Int, amount: Int)`：敌人回复（用于时间回溯）

**BattleEngine 需要新增临时状态**（仅影响玩家下一回合）：
- `var foresightPenaltyNextTurn: Int`（回合开始时生效一次，然后归零）
- `var firstCardCostIncreaseNextTurn: Int`（下一回合首张出牌生效，然后归零）
- `var didApplyFirstCardCostIncreaseThisTurn: Bool`（确保只加一次）

**修改点**：
- `applyForesight(count:)`：应用 penalty（`max(0, count - penalty)`），并在回合开始把 penalty 归零
- `playCard(...)`：在消耗能量/校验 cost 前，把首张牌 cost 临时 +N（并标记已使用）
- 新增 `BattleEvent` 用于日志/测试（可选，但强烈建议）：例如 `cipherMechanicApplied(...)`

#### P6-2 在 Cipher AI 中落地三阶段机制
**文件**：`Sources/GameCore/Enemies/Definitions/Act2/Act2BossEnemies.swift`

按设计文档映射到上面的 BattleEffect：
- 阶段 1：预知反制 → `.applyForesightPenaltyNextTurn(amount: 1)`
- 阶段 2：命运剥夺 → `.discardRandomHand(count: 2)` + `.applyStatus(.player, madness, +2)`
- 阶段 3：命运改写（敌方版）→ `.applyFirstCardCostIncreaseNextTurn(amount: 1)`
- 阶段 3：时间回溯 → `.enemyHeal(enemyIndex: selfIndex, amount: 15)`

#### P6-3 测试（必须新增）
**新增测试文件**：`Tests/GameCoreTests/CipherBossMechanicsTests.swift`
- 构造战斗：单个 Cipher（selfIndex=0）+ 固定 seed
- 断言：在不同 HP% 阶段，chooseMove 会产出对应效果
- 断言：`applyForesightPenaltyNextTurn` 会让下一回合预知 fromCount 下降（最低 0）
- 断言：`applyFirstCardCostIncreaseNextTurn` 会让下一回合第一张卡能量校验变严格

### P6 验收
```bash
swift build
swift test
SALU_TEST_MODE=1 SALU_TEST_MAP=mini SALU_TEST_MAX_FLOOR=3 swift run GameCLI --seed 1
```

---

## P7：卡牌池扩展（占卜家罕见/稀有卡 + 通用补充）✅ 已完成

> 完成日期：2026-01-12
> 包含：净化仪式/预言回响/序列共鸣（含状态）+ CardRegistry 注册 + 单元测试（`SeerAdvancedCardsTests`）

### 目标
补齐设计文档中占卜家卡牌：时间碎片、净化仪式、预言回响、深渊凝视、序列共鸣，并接入奖励/商店卡池。

### 实现步骤（可执行）
#### P7-1 补齐占卜家卡牌定义（与现有引擎能力对齐）
**文件**：`Sources/GameCore/Cards/Definitions/Seer/SeerCards.swift`

需要补齐（至少）：
- **时间碎片**：回溯 N + 抽牌 + 疯狂（需要已存在 `.rewind` + `.drawCards`）
- **净化仪式**：清除所有疯狂 +（未升级时）弃 1 张手牌  
  - 需要新增 `BattleEffect.discardRandomFromHand(count:)` 或 `BattleEffect.discardHand(cardIndex:)` 之一
- **预言回响**：造成 `X × 本回合预知次数` 伤害  
  - 需要 `BattleEngine` 追踪 `foresightCountThisTurn`（在 `applyForesight` 增加）并提供一个效果来读取它（例如 `.dealDamageBasedOnForesightCount(basePerForesight:)`）
- **深渊凝视**：预知 N，然后对所有敌人造成 `k ×（本次预知中攻击牌数量）` 伤害  
  - 推荐：`BattleEngine` 记录 `lastForesightViewedCardIds`（在 `applyForesight` 内保存），再新增效果 `.dealAOEDamageFromLastForesightAttackCount(multiplier:)`
- **序列共鸣**（能力）：本场战斗中，每次预知后获得格挡（1 或 2）  
  - 推荐：新增 `StatusDefinition`（如 `SequenceResonance`）或直接用状态 id 表示，并在 `applyForesight` 中检查该状态并产出 `.gainBlock`

#### P7-2 注册到 CardRegistry
**文件**：`Sources/GameCore/Cards/CardRegistry.swift`

#### P7-3 卡池接入策略
当前 `CardPool.rewardableCardIds()` 是“排除 starter，其余全进”，因此：
- 新增卡牌只要 rarity != starter，就会自动进入奖励/商店
- 如果要做“按序列/章节分池”，可在 P7-3.1 再拆分（后续扩展点）

#### P7-4 测试（必须新增）
- 更新 `Tests/GameCoreTests/CardDefinitionPlayTests.swift`：为新增卡牌补齐 play 行为断言
- 新增 `Tests/GameCoreTests/SeerAdvancedCardsTests.swift`：
  - 覆盖：预言回响/深渊凝视/净化仪式等需要引擎新增状态的卡

### P7 验收
```bash
swift build
swift test
SALU_TEST_MODE=1 SALU_TEST_MAP=battle swift run GameCLI --seed 1
```

## 验收流程

每完成一个 P 级别后：

```bash
# 1. 构建
swift build

# 2. 测试
swift test

# 3. 手动验收（可选）
SALU_TEST_MODE=1 SALU_TEST_MAP=battle swift run GameCLI --seed 1
```

---

## 风险点与解决方案

| 风险 | 解决方案 |
|------|----------|
| 预知需要玩家交互 | 1.0 用简化版（自动选择）；2.0 再做交互式 |
| 改写机制复杂 | 只支持"改为防御"和"跳过行动"两种 |
| 疯狂阈值检查时机 | 在 `startNewTurn` 抽牌前检查 |
| 商店扩展需要改 ShopItem | 新增 `.relic` 和 `.consumable` 两种 Kind |

---

## 下一步

P0~P4 已完成。可继续实现：
- P5：事件扩展（占卜家专属事件）
- P6：赛弗 Boss 特殊机制
- P7：卡牌池扩展（罕见/稀有卡牌）
