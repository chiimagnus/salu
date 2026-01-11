# Salu 1.0 占卜家序列 —— 详细实现计划

> 本文档基于对现有代码库的深入分析，为每个优先级提供具体的实现步骤。
> 设计草案：`.cursor/plans/design-1.0-seer-build.md`
> 总体规划：`.cursor/plans/plan-1.0-seer-implementation.md`

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
- **库存模型**：`ShopInventory`（目前只有 `cardOffers` + `removeCardPrice`）
- **条目类型**：`ShopItem.Kind`（`.card` / `.removeCard`）
- **定价**：`ShopPricing`

### 事件系统（Events）
- **位置**：`Sources/GameCore/Events/`
- **定义协议**：`EventDefinition`（`generate(context:rng:) -> EventOffer`）
- **选项模型**：`EventOption`（`title`/`preview`/`effects: [RunEffect]`/`followUp`）
- **Run效果**：`RunEffect`（gainGold/heal/addCard/addRelic/upgradeCard 等）

---

## P0：疯狂状态系统

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

## P1：核心卡牌机制

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

## P2：敌人意图扩展

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

从 P0-1 开始实现：在 `Debuffs.swift` 中添加 `Madness` 状态定义。

