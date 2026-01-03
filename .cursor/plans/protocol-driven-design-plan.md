# Salu 协议驱动开发重构计划 (Plan A)

> 创建时间：2026-01-03
> 状态：待实施

---

## 📋 概述

本计划将 Salu 项目从**枚举+Switch**模式重构为**协议驱动开发（Protocol-Oriented Programming）**模式，以支持更灵活的扩展性，便于添加更多卡牌和敌人。

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
| **房间类型** | `RoomType` 枚举 | 添加新房间类型需修改枚举 |

### 应保持枚举的模块 ✓

| 模块 | 原因 |
|------|------|
| `BattleEvent` | 事件类型有限且稳定，枚举更适合模式匹配 |
| `PlayerAction` | 玩家动作类型有限且稳定 |
| `EnemyIntent` | 意图类型有限且稳定 |

---

## 🎯 重构优先级

```
┌────────────────────────────────────────────────────────────────┐
│  P1: 卡牌系统协议化                    ⭐⭐⭐ 最重要           │
│  ├── CardEffect 协议                                           │
│  ├── 所有卡牌实现独立结构体                                    │
│  └── CardRegistry 卡牌注册表                                   │
├────────────────────────────────────────────────────────────────┤
│  P2: 状态效果系统协议化                ⭐⭐ 重要               │
│  ├── StatusEffect 协议                                         │
│  ├── 易伤/虚弱/力量实现                                        │
│  └── StatusManager 状态管理器                                  │
├────────────────────────────────────────────────────────────────┤
│  P3: 敌人数据系统完善                  ⭐⭐ 重要               │
│  ├── EnemyDefinition 协议                                      │
│  ├── 统一敌人配置                                              │
│  └── EnemyRegistry 敌人注册表                                  │
├────────────────────────────────────────────────────────────────┤
│  P4: 房间系统协议化                    ⭐ 一般                 │
│  ├── Room 协议                                                 │
│  └── 各类房间实现                                              │
├────────────────────────────────────────────────────────────────┤
│  P5: 遗物系统设计                      ⭐ 一般                 │
│  ├── Relic 协议                                                │
│  └── 触发器机制                                                │
└────────────────────────────────────────────────────────────────┘
```

---

## P1: 卡牌系统协议化 ⭐⭐⭐

### 目标
- 将每张卡牌抽象为独立的结构体，实现统一协议
- 添加新卡牌只需创建新结构体，无需修改现有代码
- 支持复杂的卡牌效果组合

### 新架构设计

```
Sources/GameCore/Cards/
├── Protocols/
│   ├── CardDefinition.swift      # 卡牌定义协议
│   └── CardEffect.swift          # 卡牌效果协议
├── Definitions/
│   ├── BasicCards.swift          # 基础卡牌（Strike, Defend）
│   ├── AttackCards.swift         # 攻击卡牌
│   ├── SkillCards.swift          # 技能卡牌
│   └── PowerCards.swift          # 能力卡牌
├── Effects/
│   ├── DamageEffect.swift        # 伤害效果
│   ├── BlockEffect.swift         # 格挡效果
│   ├── DrawEffect.swift          # 抽牌效果
│   ├── StatusEffect.swift        # 状态效果
│   └── CompositeEffect.swift     # 组合效果
├── CardRegistry.swift            # 卡牌注册表
├── Card.swift                    # 卡牌实例（运行时）
└── StarterDeck.swift             # 初始牌组（保留）
```

### 协议设计

```swift
// ═══════════════════════════════════════════════════════════════
// CardDefinition.swift - 卡牌定义协议
// ═══════════════════════════════════════════════════════════════

/// 卡牌定义协议
/// 每种卡牌实现此协议，定义其属性和效果
public protocol CardDefinition: Sendable {
    /// 卡牌唯一标识符（如 "strike", "defend"）
    static var id: String { get }
    
    /// 显示名称
    static var displayName: String { get }
    
    /// 卡牌类型
    static var cardType: CardType { get }
    
    /// 稀有度
    static var rarity: CardRarity { get }
    
    /// 能量消耗
    static var cost: Int { get }
    
    /// 卡牌描述（支持动态值）
    static var description: String { get }
    
    /// 执行卡牌效果
    static func execute(context: CardExecutionContext) -> [CardEffectResult]
    
    /// 计算最终伤害（用于 UI 显示，考虑力量/虚弱/易伤）
    static func calculateDisplayDamage(context: CardExecutionContext) -> Int?
    
    /// 计算最终格挡（用于 UI 显示，考虑敏捷等）
    static func calculateDisplayBlock(context: CardExecutionContext) -> Int?
}

/// 卡牌类型
public enum CardType: String, Sendable {
    case attack = "攻击"
    case skill = "技能"
    case power = "能力"
    case status = "状态"  // 负面卡牌
    case curse = "诅咒"   // 诅咒卡牌
}

/// 卡牌稀有度
public enum CardRarity: String, Sendable {
    case basic = "基础"
    case common = "普通"
    case uncommon = "罕见"
    case rare = "稀有"
}

/// 卡牌执行上下文
/// 包含执行效果所需的所有信息
public struct CardExecutionContext: Sendable {
    public let player: Entity
    public let enemy: Entity
    public let battleState: BattleState
    
    public init(player: Entity, enemy: Entity, battleState: BattleState) {
        self.player = player
        self.enemy = enemy
        self.battleState = battleState
    }
}

/// 卡牌效果结果
/// 描述卡牌执行后产生的具体效果
public enum CardEffectResult: Sendable {
    case dealDamage(target: EffectTarget, baseDamage: Int)
    case gainBlock(target: EffectTarget, amount: Int)
    case applyStatus(target: EffectTarget, status: StatusType, stacks: Int)
    case drawCards(count: Int)
    case gainEnergy(amount: Int)
    case heal(target: EffectTarget, amount: Int)
    case custom(effect: AnyCardEffect)
}

/// 效果目标
public enum EffectTarget: Sendable {
    case player
    case enemy
    case allEnemies
    case random
}

/// 状态类型
public enum StatusType: String, Sendable {
    case vulnerable = "易伤"
    case weak = "虚弱"
    case strength = "力量"
    case dexterity = "敏捷"
    case frail = "脆弱"
    case poison = "中毒"
    // ... 可扩展更多
}
```

### 卡牌实现示例

```swift
// ═══════════════════════════════════════════════════════════════
// BasicCards.swift - 基础卡牌实现
// ═══════════════════════════════════════════════════════════════

/// Strike - 基础攻击牌
public struct StrikeCard: CardDefinition {
    public static let id = "strike"
    public static let displayName = "Strike"
    public static let cardType: CardType = .attack
    public static let rarity: CardRarity = .basic
    public static let cost = 1
    
    public static var description: String {
        "造成 6 点伤害"
    }
    
    public static func execute(context: CardExecutionContext) -> [CardEffectResult] {
        [.dealDamage(target: .enemy, baseDamage: 6)]
    }
    
    public static func calculateDisplayDamage(context: CardExecutionContext) -> Int? {
        DamageCalculator.calculate(
            baseDamage: 6,
            attacker: context.player,
            defender: context.enemy
        )
    }
    
    public static func calculateDisplayBlock(context: CardExecutionContext) -> Int? {
        nil
    }
}

/// Defend - 基础防御牌
public struct DefendCard: CardDefinition {
    public static let id = "defend"
    public static let displayName = "Defend"
    public static let cardType: CardType = .skill
    public static let rarity: CardRarity = .basic
    public static let cost = 1
    
    public static var description: String {
        "获得 5 点格挡"
    }
    
    public static func execute(context: CardExecutionContext) -> [CardEffectResult] {
        [.gainBlock(target: .player, amount: 5)]
    }
    
    public static func calculateDisplayDamage(context: CardExecutionContext) -> Int? {
        nil
    }
    
    public static func calculateDisplayBlock(context: CardExecutionContext) -> Int? {
        5  // 未来可以考虑敏捷加成
    }
}

/// Bash - 重击
public struct BashCard: CardDefinition {
    public static let id = "bash"
    public static let displayName = "Bash"
    public static let cardType: CardType = .attack
    public static let rarity: CardRarity = .basic
    public static let cost = 2
    
    public static var description: String {
        "造成 8 点伤害，施加 2 层易伤"
    }
    
    public static func execute(context: CardExecutionContext) -> [CardEffectResult] {
        [
            .dealDamage(target: .enemy, baseDamage: 8),
            .applyStatus(target: .enemy, status: .vulnerable, stacks: 2)
        ]
    }
    
    public static func calculateDisplayDamage(context: CardExecutionContext) -> Int? {
        DamageCalculator.calculate(
            baseDamage: 8,
            attacker: context.player,
            defender: context.enemy
        )
    }
    
    public static func calculateDisplayBlock(context: CardExecutionContext) -> Int? {
        nil
    }
}

/// Pommel Strike - 柄击
public struct PommelStrikeCard: CardDefinition {
    public static let id = "pommel_strike"
    public static let displayName = "Pommel Strike"
    public static let cardType: CardType = .attack
    public static let rarity: CardRarity = .common
    public static let cost = 1
    
    public static var description: String {
        "造成 9 点伤害，抽 1 张牌"
    }
    
    public static func execute(context: CardExecutionContext) -> [CardEffectResult] {
        [
            .dealDamage(target: .enemy, baseDamage: 9),
            .drawCards(count: 1)
        ]
    }
    
    public static func calculateDisplayDamage(context: CardExecutionContext) -> Int? {
        DamageCalculator.calculate(
            baseDamage: 9,
            attacker: context.player,
            defender: context.enemy
        )
    }
    
    public static func calculateDisplayBlock(context: CardExecutionContext) -> Int? {
        nil
    }
}
```

### 卡牌注册表

```swift
// ═══════════════════════════════════════════════════════════════
// CardRegistry.swift - 卡牌注册表
// ═══════════════════════════════════════════════════════════════

/// 卡牌注册表
/// 集中管理所有卡牌定义，支持按 ID 查找
public enum CardRegistry {
    
    /// 注册的卡牌类型映射
    private static let definitions: [String: any CardDefinition.Type] = [
        StrikeCard.id: StrikeCard.self,
        DefendCard.id: DefendCard.self,
        BashCard.id: BashCard.self,
        PommelStrikeCard.id: PommelStrikeCard.self,
        ShrugItOffCard.id: ShrugItOffCard.self,
        InflameCard.id: InflameCard.self,
        ClotheslineCard.id: ClotheslineCard.self,
        // ... 添加更多卡牌
    ]
    
    /// 根据 ID 获取卡牌定义
    public static func get(_ id: String) -> (any CardDefinition.Type)? {
        definitions[id]
    }
    
    /// 获取所有已注册的卡牌 ID
    public static var allCardIds: [String] {
        Array(definitions.keys)
    }
    
    /// 根据稀有度获取卡牌
    public static func cards(ofRarity rarity: CardRarity) -> [any CardDefinition.Type] {
        definitions.values.filter { $0.rarity == rarity }
    }
    
    /// 根据类型获取卡牌
    public static func cards(ofType type: CardType) -> [any CardDefinition.Type] {
        definitions.values.filter { $0.cardType == type }
    }
}
```

### BattleEngine 重构

```swift
// 在 BattleEngine 中使用协议驱动的卡牌效果执行
private func executeCardEffect(_ card: Card) {
    guard let definition = CardRegistry.get(card.definitionId) else {
        emit(.invalidAction(reason: "未知卡牌: \(card.definitionId)"))
        return
    }
    
    // 构建执行上下文
    let context = CardExecutionContext(
        player: state.player,
        enemy: state.enemy,
        battleState: state
    )
    
    // 获取效果列表
    let effects = definition.execute(context: context)
    
    // 执行每个效果
    for effect in effects {
        executeEffect(effect)
    }
}

private func executeEffect(_ effect: CardEffectResult) {
    switch effect {
    case .dealDamage(let target, let baseDamage):
        executeDamage(target: target, baseDamage: baseDamage)
        
    case .gainBlock(let target, let amount):
        executeBlock(target: target, amount: amount)
        
    case .applyStatus(let target, let status, let stacks):
        executeApplyStatus(target: target, status: status, stacks: stacks)
        
    case .drawCards(let count):
        drawCards(count)
        
    case .gainEnergy(let amount):
        state.energy += amount
        emit(.energyGained(amount: amount))
        
    case .heal(let target, let amount):
        executeHeal(target: target, amount: amount)
        
    case .custom(let customEffect):
        customEffect.execute(engine: self)
    }
}
```

### 实施步骤

| 步骤 | 内容 | 复杂度 | 预计时间 |
|------|------|--------|----------|
| P1.1 | 创建 `CardDefinition` 协议和相关类型 | ⭐ | 20分钟 |
| P1.2 | 创建 `CardEffectResult` 枚举 | ⭐ | 15分钟 |
| P1.3 | 实现 `StrikeCard`, `DefendCard` 基础卡牌 | ⭐ | 15分钟 |
| P1.4 | 实现其他现有卡牌（Bash, PommelStrike 等） | ⭐ | 30分钟 |
| P1.5 | 创建 `CardRegistry` 注册表 | ⭐ | 15分钟 |
| P1.6 | 重构 `Card` 结构体使用 `definitionId` | ⭐⭐ | 20分钟 |
| P1.7 | 重构 `BattleEngine.executeCardEffect()` | ⭐⭐ | 30分钟 |
| P1.8 | 更新 `StarterDeck` 使用新的卡牌系统 | ⭐ | 10分钟 |
| P1.9 | 更新 UI 层获取卡牌信息的方式 | ⭐ | 15分钟 |
| P1.10 | 添加 2-3 张新卡牌验证扩展性 | ⭐ | 20分钟 |
| **总计** | | | **~3小时** |

### 验收标准

- [ ] 所有现有卡牌迁移到协议驱动模式
- [ ] 添加新卡牌只需创建新结构体 + 注册到 CardRegistry
- [ ] 所有测试通过
- [ ] `swift build` 成功

---

## P2: 状态效果系统协议化 ⭐⭐

### 目标
- 将状态效果（易伤、虚弱、力量等）抽象为协议
- 支持添加新的状态效果（中毒、敏捷、脆弱等）
- 统一状态效果的触发时机

### 新架构设计

```
Sources/GameCore/Status/
├── StatusEffect.swift            # 状态效果协议
├── StatusManager.swift           # 状态管理器
├── Effects/
│   ├── VulnerableEffect.swift    # 易伤
│   ├── WeakEffect.swift          # 虚弱
│   ├── StrengthEffect.swift      # 力量
│   ├── DexterityEffect.swift     # 敏捷
│   ├── PoisonEffect.swift        # 中毒
│   └── ...
└── StatusRegistry.swift          # 状态注册表
```

### 协议设计

```swift
/// 状态效果协议
public protocol StatusEffect: Sendable {
    /// 状态唯一标识符
    static var id: String { get }
    
    /// 显示名称
    static var displayName: String { get }
    
    /// 显示图标
    static var icon: String { get }
    
    /// 是否为正面效果
    static var isPositive: Bool { get }
    
    /// 是否随时间递减
    static var decaysOverTime: Bool { get }
    
    /// 修正造成的伤害
    static func modifyOutgoingDamage(_ damage: Int, stacks: Int) -> Int
    
    /// 修正受到的伤害
    static func modifyIncomingDamage(_ damage: Int, stacks: Int) -> Int
    
    /// 修正格挡
    static func modifyBlock(_ block: Int, stacks: Int) -> Int
    
    /// 回合结束时触发
    static func onTurnEnd(entity: inout Entity, stacks: Int) -> [BattleEvent]
}
```

### 实施步骤

| 步骤 | 内容 | 复杂度 | 预计时间 |
|------|------|--------|----------|
| P2.1 | 创建 `StatusEffect` 协议 | ⭐ | 15分钟 |
| P2.2 | 创建 `StatusManager` 管理器 | ⭐⭐ | 30分钟 |
| P2.3 | 实现 `VulnerableEffect` | ⭐ | 15分钟 |
| P2.4 | 实现 `WeakEffect` | ⭐ | 15分钟 |
| P2.5 | 实现 `StrengthEffect` | ⭐ | 15分钟 |
| P2.6 | 重构 `Entity` 使用 `StatusManager` | ⭐⭐ | 30分钟 |
| P2.7 | 重构 `BattleEngine` 伤害计算 | ⭐⭐ | 30分钟 |
| P2.8 | 添加 2 个新状态效果验证扩展性（敏捷、中毒） | ⭐ | 30分钟 |
| **总计** | | | **~3小时** |

### 验收标准

- [ ] 现有状态效果迁移到协议模式
- [ ] 添加新状态只需创建新结构体
- [ ] 中毒效果正常工作（回合结束造成伤害）
- [ ] 敏捷效果正常工作（增加格挡）
- [ ] 所有测试通过

---

## P3: 敌人数据系统完善 ⭐⭐

### 目标
- 统一敌人定义为协议
- 将敌人数据和 AI 行为合并到一个定义中
- 支持更复杂的敌人行为模式

### 新架构设计

```
Sources/GameCore/Enemies/
├── EnemyDefinition.swift         # 敌人定义协议
├── Definitions/
│   ├── Act1Enemies.swift         # 第一章敌人
│   │   ├── JawWorm
│   │   ├── Cultist
│   │   ├── LouseGreen
│   │   ├── LouseRed
│   │   └── SlimeMediumAcid
│   ├── Act1Elites.swift          # 第一章精英
│   └── Act1Boss.swift            # 第一章 Boss
├── EnemyRegistry.swift           # 敌人注册表
├── EnemyPool.swift               # 敌人池（保留）
├── EnemyIntent.swift             # 意图类型（保留）
└── EnemyAI.swift                 # AI 协议（保留，重命名为 EnemyBehavior）
```

### 协议设计

```swift
/// 敌人定义协议
/// 将敌人数据和 AI 行为统一到一个定义中
public protocol EnemyDefinition: Sendable {
    /// 敌人唯一标识符
    static var id: String { get }
    
    /// 显示名称
    static var displayName: String { get }
    
    /// HP 范围
    static var hpRange: ClosedRange<Int> { get }
    
    /// 基础攻击力
    static var baseAttack: Int { get }
    
    /// 敌人描述
    static var description: String { get }
    
    /// 决定下一个意图
    static func decideIntent(
        enemy: Entity,
        player: Entity,
        turn: Int,
        rng: inout SeededRNG
    ) -> EnemyIntent
    
    /// 生成敌人实体
    static func spawn(rng: inout SeededRNG) -> Entity
}

// 提供默认实现
extension EnemyDefinition {
    public static func spawn(rng: inout SeededRNG) -> Entity {
        let hp = hpRange.lowerBound + rng.nextInt(upperBound: hpRange.count)
        return Entity(
            id: id,
            name: displayName,
            maxHP: hp,
            enemyDefinitionId: id
        )
    }
}
```

### 敌人实现示例

```swift
/// 下颚虫
public struct JawWormEnemy: EnemyDefinition {
    public static let id = "jaw_worm"
    public static let displayName = "下颚虫"
    public static let hpRange = 40...44
    public static let baseAttack = 11
    public static let description = "凶猛的虫类敌人"
    
    public static func decideIntent(
        enemy: Entity,
        player: Entity,
        turn: Int,
        rng: inout SeededRNG
    ) -> EnemyIntent {
        let roll = rng.nextInt(upperBound: 100)
        let baseDamage = baseAttack + enemy.strength
        
        if turn == 1 {
            return roll < 75 ? .attack(damage: baseDamage) : .buff(name: "力量", stacks: 3)
        }
        
        if roll < 45 {
            return .attack(damage: baseDamage)
        } else if roll < 75 {
            return .buff(name: "力量", stacks: 3)
        } else {
            return .attack(damage: 7 + enemy.strength)
        }
    }
}
```

### 实施步骤

| 步骤 | 内容 | 复杂度 | 预计时间 |
|------|------|--------|----------|
| P3.1 | 创建 `EnemyDefinition` 协议 | ⭐ | 15分钟 |
| P3.2 | 迁移现有 5 种敌人到新协议 | ⭐⭐ | 45分钟 |
| P3.3 | 创建 `EnemyRegistry` 注册表 | ⭐ | 15分钟 |
| P3.4 | 重构 `Entity` 使用 `enemyDefinitionId` | ⭐ | 15分钟 |
| P3.5 | 重构 `BattleEngine` 使用新的敌人系统 | ⭐⭐ | 30分钟 |
| P3.6 | 重构 `EnemyPool` 使用注册表 | ⭐ | 15分钟 |
| P3.7 | 删除旧的 `EnemyKind`, `EnemyData`, `EnemyBehaviors` | ⭐ | 10分钟 |
| P3.8 | 添加 2 个新敌人验证扩展性 | ⭐ | 30分钟 |
| **总计** | | | **~3小时** |

### 验收标准

- [ ] 现有 5 种敌人迁移到协议模式
- [ ] 添加新敌人只需创建新结构体 + 注册
- [ ] 删除旧的敌人相关代码
- [ ] 所有测试通过

---

## P4: 房间系统协议化 ⭐

### 目标
- 将房间类型抽象为协议
- 支持添加更多房间类型（商店、事件、宝箱等）

### 新架构设计

```
Sources/GameCore/Rooms/
├── RoomDefinition.swift          # 房间定义协议
├── Definitions/
│   ├── BattleRoom.swift          # 战斗房间
│   ├── EliteRoom.swift           # 精英房间
│   ├── RestRoom.swift            # 休息房间
│   ├── BossRoom.swift            # Boss 房间
│   ├── ShopRoom.swift            # 商店房间
│   ├── EventRoom.swift           # 事件房间
│   └── TreasureRoom.swift        # 宝箱房间
└── RoomRegistry.swift            # 房间注册表
```

### 实施步骤

| 步骤 | 内容 | 复杂度 | 预计时间 |
|------|------|--------|----------|
| P4.1 | 创建 `RoomDefinition` 协议 | ⭐ | 15分钟 |
| P4.2 | 迁移现有房间类型 | ⭐ | 30分钟 |
| P4.3 | 创建 `RoomRegistry` 注册表 | ⭐ | 15分钟 |
| P4.4 | 重构 `MapNode` 和 `MapGenerator` | ⭐⭐ | 30分钟 |
| P4.5 | 添加商店房间基础实现 | ⭐⭐ | 45分钟 |
| **总计** | | | **~2.5小时** |

---

## P5: 遗物系统设计 ⭐

### 目标
- 设计遗物系统协议
- 支持多种触发时机

### 新架构设计

```
Sources/GameCore/Relics/
├── RelicDefinition.swift         # 遗物定义协议
├── RelicTrigger.swift            # 触发时机
├── RelicManager.swift            # 遗物管理器
├── Definitions/
│   ├── StarterRelics.swift       # 起始遗物
│   └── CommonRelics.swift        # 普通遗物
└── RelicRegistry.swift           # 遗物注册表
```

### 实施步骤

| 步骤 | 内容 | 复杂度 | 预计时间 |
|------|------|--------|----------|
| P5.1 | 创建 `RelicDefinition` 协议 | ⭐ | 20分钟 |
| P5.2 | 创建 `RelicTrigger` 触发系统 | ⭐⭐ | 45分钟 |
| P5.3 | 创建 `RelicManager` 管理器 | ⭐⭐ | 30分钟 |
| P5.4 | 实现 3 个基础遗物 | ⭐ | 30分钟 |
| P5.5 | 集成到 `RunState` 和 `BattleEngine` | ⭐⭐ | 45分钟 |
| **总计** | | | **~3小时** |

---

## 📅 实施时间表

```
Week 1
├── P1: 卡牌系统协议化（~3小时）
│   ├── Day 1: P1.1 - P1.5 协议和基础卡牌
│   └── Day 2: P1.6 - P1.10 重构和验证
│
├── [验证点] swift build + 测试
│
Week 1-2
├── P2: 状态效果系统协议化（~3小时）
│   ├── Day 3: P2.1 - P2.5 协议和基础效果
│   └── Day 4: P2.6 - P2.8 重构和新效果
│
├── [验证点] swift build + 测试
│
Week 2
├── P3: 敌人数据系统完善（~3小时）
│   ├── Day 5: P3.1 - P3.4 协议和迁移
│   └── Day 6: P3.5 - P3.8 重构和新敌人
│
├── [验证点] swift build + 测试
│
Week 2-3
├── P4: 房间系统协议化（~2.5小时）
│   └── Day 7: 全部步骤
│
├── [验证点] swift build + 测试
│
Week 3
├── P5: 遗物系统设计（~3小时）
│   ├── Day 8: P5.1 - P5.3 协议和管理器
│   └── Day 9: P5.4 - P5.5 实现和集成
│
└── [最终验证] swift build + 完整测试
```

---

## ⚠️ 风险与注意事项

### 1. 向后兼容性

由于这是一个破坏性重构，需要注意：
- 战绩数据中可能存储了旧的卡牌 ID，需要迁移
- 存档系统（如果有）需要更新

### 2. 性能考虑

- 协议的动态派发可能比枚举的静态派发稍慢
- 对于热路径（如伤害计算），可以考虑使用 `@inlinable`

### 3. 测试策略

每完成一个优先级后：
1. 运行 `swift build` 确保编译通过
2. 运行现有测试确保功能正常
3. 手动测试关键流程

---

## 📝 修订历史

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-01-03 | v1.0 | 初稿 |

