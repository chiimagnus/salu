# Salu 协议驱动开发重构计划 (Plan A)

> 创建时间：2026-01-03
> 状态：待实施
> **最后审视：2026-01-03 - 修复依赖关系和设计缺陷**

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
| **房间类型** | `RoomType` 枚举 | 当前已足够，**无需协议化** |

### 应保持枚举的模块 ✓

| 模块 | 原因 |
|------|------|
| `BattleEvent` | 事件类型有限且稳定，枚举更适合模式匹配 |
| `PlayerAction` | 玩家动作类型有限且稳定 |
| `EnemyIntent` | 意图类型有限且稳定 |
| `RoomType` | 房间类型相对固定，枚举更简洁 |

---

## 🎯 重构优先级（修订版）

```
┌────────────────────────────────────────────────────────────────┐
│  P1: 卡牌系统协议化                    ⭐⭐⭐ 最重要           │
│  ├── CardDefinition 协议                                       │
│  ├── CardEffectResult 效果描述枚举                             │
│  ├── DamageCalculator 伤害计算工具（提取现有逻辑）              │
│  ├── 所有卡牌实现独立结构体                                    │
│  ├── CardRegistry 卡牌注册表                                   │
│  └── 卡牌升级系统支持（upgraded 属性）                         │
├────────────────────────────────────────────────────────────────┤
│  P2: 状态效果系统协议化                ⭐⭐ 重要               │
│  ├── StatusEffectDefinition 协议                               │
│  ├── StatusType 枚举（从 P1 移除，在此定义）                   │
│  ├── StatusContainer 状态容器（替代 Entity 中的硬编码）        │
│  ├── 易伤/虚弱/力量/敏捷/中毒 实现                             │
│  └── 与 BattleEngine 伤害计算集成                              │
├────────────────────────────────────────────────────────────────┤
│  P3: 敌人系统统一                      ⭐⭐ 重要               │
│  ├── EnemyDefinition 协议（合并 EnemyData + EnemyAI）          │
│  ├── 保留 EnemyIntent 枚举                                     │
│  ├── EnemyRegistry 敌人注册表                                  │
│  ├── 迁移现有 5 种敌人                                         │
│  └── 添加 2 个新敌人验证                                       │
├────────────────────────────────────────────────────────────────┤
│  P4: 遗物系统设计                      ⭐ 一般                 │
│  ├── RelicDefinition 协议                                      │
│  ├── RelicTriggerType 触发时机枚举                             │
│  ├── RelicManager 遗物管理器                                   │
│  └── 3 个基础遗物实现                                          │
└────────────────────────────────────────────────────────────────┘

已移除：
- P4(旧): 房间系统协议化 → RoomType 枚举已足够，无需过度设计
```

---

## ⚠️ 已识别的设计问题与修复

### 问题 1：P1 中使用了未定义的类型

| 问题 | 修复方案 |
|------|----------|
| `AnyCardEffect` 未定义 | 移除 `custom(effect:)` case，改用更具体的效果类型 |
| `DamageCalculator` 未定义 | 在 P1.1 中创建，提取 BattleEngine 现有伤害计算逻辑 |
| `StatusType` 应在 P2 | P1 中使用字符串表示状态，P2 完成后替换为枚举 |

### 问题 2：卡牌升级系统缺失

```swift
// 修复：添加 upgraded 属性支持
public protocol CardDefinition: Sendable {
    // ... 现有属性 ...
    
    /// 是否为升级版卡牌
    static var isUpgraded: Bool { get }
    
    /// 升级版卡牌定义 ID（可选）
    static var upgradedVersionId: String? { get }
}

// 默认实现
extension CardDefinition {
    public static var isUpgraded: Bool { false }
    public static var upgradedVersionId: String? { nil }
}
```

### 问题 3：P2 与 Entity 的集成

```swift
// 修复：使用 StatusContainer 而非修改 Entity 结构
public struct StatusContainer: Sendable {
    private var statuses: [String: Int] = [:]  // statusId -> stacks
    
    public func getStacks(_ statusId: String) -> Int {
        statuses[statusId] ?? 0
    }
    
    public mutating func apply(_ statusId: String, stacks: Int) {
        statuses[statusId, default: 0] += stacks
    }
    
    public mutating func tick() -> [String] {
        // 递减所有可递减的状态
        var expired: [String] = []
        for (statusId, _) in statuses {
            guard let definition = StatusRegistry.get(statusId) else { continue }
            if definition.decaysOverTime {
                statuses[statusId]! -= 1
                if statuses[statusId]! <= 0 {
                    statuses.removeValue(forKey: statusId)
                    expired.append(statusId)
                }
            }
        }
        return expired
    }
}

// Entity 修改：替换现有的 vulnerable/weak/strength 属性
public struct Entity: Sendable {
    // ... 保留 id, name, maxHP, currentHP, block ...
    
    /// 状态效果容器（替代 vulnerable, weak, strength）
    public var statuses: StatusContainer = StatusContainer()
    
    // 兼容性便捷属性
    public var vulnerable: Int {
        get { statuses.getStacks("vulnerable") }
        set { statuses.apply("vulnerable", stacks: newValue - vulnerable) }
    }
    // ... 其他兼容性属性 ...
}
```

### 问题 4：P3 与现有 EnemyAI 的关系

```
方案：合并而非替代

当前：
┌───────────────┐    ┌─────────────┐
│  EnemyKind    │    │  EnemyAI    │
│  (枚举)        │    │  (协议)      │
└───────┬───────┘    └──────┬──────┘
        │                    │
        ▼                    ▼
┌───────────────┐    ┌─────────────┐
│  EnemyData    │    │ JawWormAI   │
│  (静态数据)    │    │ CultistAI   │
└───────────────┘    │ ...         │
                     └─────────────┘

目标：统一为 EnemyDefinition
┌───────────────────────────────────┐
│       EnemyDefinition             │
│  ├── id, displayName, hpRange    │
│  ├── baseAttack, description     │
│  └── decideIntent()              │
└───────────────────────────────────┘
        ▼
┌─────────────────┐
│ JawWormEnemy    │
│ CultistEnemy    │
│ LouseGreenEnemy │
│ ...             │
└─────────────────┘

迁移策略：
1. 创建新的 EnemyDefinition 协议
2. 将现有 EnemyData + 对应 AI 合并到新结构体
3. 更新 BattleEngine 使用 EnemyRegistry
4. 最后删除旧的 EnemyKind, EnemyData, EnemyAI, EnemyBehaviors
```

### 问题 5：CardKind 枚举的处理

```
迁移策略：
1. P1 完成后，CardKind 暂时保留用于向后兼容
2. Card 结构体添加 definitionId 字段，同时保留 kind 字段
3. BattleEngine 优先使用 definitionId，回退到 kind
4. 所有功能验证正确后，下个版本删除 kind
```

---

## P1: 卡牌系统协议化 ⭐⭐⭐

### 目标
- 将每张卡牌抽象为独立的结构体，实现统一协议
- 添加新卡牌只需创建新结构体，无需修改现有代码
- 支持复杂的卡牌效果组合
- **支持卡牌升级系统**

### 新架构设计

```
Sources/GameCore/Cards/
├── Protocols/
│   └── CardDefinition.swift      # 卡牌定义协议
├── Definitions/
│   ├── BasicCards.swift          # 基础卡牌（Strike, Defend, Bash）
│   ├── CommonCards.swift         # 普通卡牌
│   └── UncommonCards.swift       # 罕见卡牌
├── CardEffectResult.swift        # 卡牌效果描述枚举
├── DamageCalculator.swift        # 伤害计算工具（从 BattleEngine 提取）
├── CardRegistry.swift            # 卡牌注册表
├── Card.swift                    # 卡牌实例（运行时）- 修改
├── CardKind.swift                # 保留，用于向后兼容
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
    /// 卡牌唯一标识符（如 "strike", "strike_plus"）
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
    
    /// 是否为升级版卡牌
    static var isUpgraded: Bool { get }
    
    /// 升级版卡牌 ID（基础卡牌返回升级版 ID，升级版返回 nil）
    static var upgradedVersionId: String? { get }
    
    /// 执行卡牌效果
    static func execute(context: CardExecutionContext) -> [CardEffectResult]
    
    /// 基础伤害值（用于 UI 显示计算）
    static var baseDamage: Int? { get }
    
    /// 基础格挡值（用于 UI 显示计算）
    static var baseBlock: Int? { get }
}

// 提供默认实现
extension CardDefinition {
    public static var isUpgraded: Bool { false }
    public static var upgradedVersionId: String? { nil }
    public static var baseDamage: Int? { nil }
    public static var baseBlock: Int? { nil }
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
```

```swift
// ═══════════════════════════════════════════════════════════════
// CardEffectResult.swift - 卡牌效果描述
// ═══════════════════════════════════════════════════════════════

/// 卡牌效果结果
/// 描述卡牌执行后产生的具体效果
/// 注意：状态使用字符串 ID，P2 完成后会有 StatusRegistry 支持
public enum CardEffectResult: Sendable, Equatable {
    /// 造成伤害
    case dealDamage(target: EffectTarget, baseDamage: Int)
    
    /// 获得格挡
    case gainBlock(target: EffectTarget, amount: Int)
    
    /// 施加状态效果（使用字符串 ID，如 "vulnerable", "weak"）
    case applyStatus(target: EffectTarget, statusId: String, stacks: Int)
    
    /// 抽牌
    case drawCards(count: Int)
    
    /// 获得能量
    case gainEnergy(amount: Int)
    
    /// 治疗
    case heal(target: EffectTarget, amount: Int)
    
    /// 弃牌
    case discardCards(count: Int)
    
    /// 消耗（移除卡牌，不进入弃牌堆）
    case exhaust
}

/// 效果目标
public enum EffectTarget: String, Sendable, Equatable {
    case `self` = "self"       // 自己（玩家使用时指玩家）
    case enemy = "enemy"       // 敌人
    case allEnemies = "all"    // 所有敌人（未来多敌人支持）
}
```

```swift
// ═══════════════════════════════════════════════════════════════
// DamageCalculator.swift - 伤害计算工具
// ═══════════════════════════════════════════════════════════════

/// 伤害计算器
/// 从 BattleEngine 提取的伤害计算逻辑，便于复用
public enum DamageCalculator {
    
    /// 计算最终伤害（应用力量、虚弱、易伤修正）
    /// - Parameters:
    ///   - baseDamage: 基础伤害
    ///   - attacker: 攻击者
    ///   - defender: 防御者
    /// - Returns: 最终伤害值
    public static func calculate(
        baseDamage: Int,
        attacker: Entity,
        defender: Entity
    ) -> Int {
        var damage = baseDamage
        
        // 力量加成
        damage += attacker.strength
        
        // 虚弱减伤（-25%，向下取整）
        if attacker.weak > 0 {
            damage = Int(Double(damage) * 0.75)
        }
        
        // 易伤增伤（+50%，向下取整）
        if defender.vulnerable > 0 {
            damage = Int(Double(damage) * 1.5)
        }
        
        return max(0, damage)
    }
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
    public static let baseDamage: Int? = 6
    public static let upgradedVersionId: String? = "strike_plus"
    
    public static var description: String { "造成 6 点伤害" }
    
    public static func execute(context: CardExecutionContext) -> [CardEffectResult] {
        [.dealDamage(target: .enemy, baseDamage: 6)]
    }
}

/// Strike+ - 升级版
public struct StrikePlusCard: CardDefinition {
    public static let id = "strike_plus"
    public static let displayName = "Strike+"
    public static let cardType: CardType = .attack
    public static let rarity: CardRarity = .basic
    public static let cost = 1
    public static let baseDamage: Int? = 9
    public static let isUpgraded = true
    
    public static var description: String { "造成 9 点伤害" }
    
    public static func execute(context: CardExecutionContext) -> [CardEffectResult] {
        [.dealDamage(target: .enemy, baseDamage: 9)]
    }
}

/// Defend - 基础防御牌
public struct DefendCard: CardDefinition {
    public static let id = "defend"
    public static let displayName = "Defend"
    public static let cardType: CardType = .skill
    public static let rarity: CardRarity = .basic
    public static let cost = 1
    public static let baseBlock: Int? = 5
    public static let upgradedVersionId: String? = "defend_plus"
    
    public static var description: String { "获得 5 点格挡" }
    
    public static func execute(context: CardExecutionContext) -> [CardEffectResult] {
        [.gainBlock(target: .`self`, amount: 5)]
    }
}

/// Bash - 重击
public struct BashCard: CardDefinition {
    public static let id = "bash"
    public static let displayName = "Bash"
    public static let cardType: CardType = .attack
    public static let rarity: CardRarity = .basic
    public static let cost = 2
    public static let baseDamage: Int? = 8
    public static let upgradedVersionId: String? = "bash_plus"
    
    public static var description: String { "造成 8 点伤害，施加 2 层易伤" }
    
    public static func execute(context: CardExecutionContext) -> [CardEffectResult] {
        [
            .dealDamage(target: .enemy, baseDamage: 8),
            .applyStatus(target: .enemy, statusId: "vulnerable", stacks: 2)
        ]
    }
}

/// Pommel Strike - 柄击
public struct PommelStrikeCard: CardDefinition {
    public static let id = "pommel_strike"
    public static let displayName = "Pommel Strike"
    public static let cardType: CardType = .attack
    public static let rarity: CardRarity = .common
    public static let cost = 1
    public static let baseDamage: Int? = 9
    
    public static var description: String { "造成 9 点伤害，抽 1 张牌" }
    
    public static func execute(context: CardExecutionContext) -> [CardEffectResult] {
        [
            .dealDamage(target: .enemy, baseDamage: 9),
            .drawCards(count: 1)
        ]
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
        // 基础卡牌
        StrikeCard.id: StrikeCard.self,
        StrikePlusCard.id: StrikePlusCard.self,
        DefendCard.id: DefendCard.self,
        DefendPlusCard.id: DefendPlusCard.self,
        BashCard.id: BashCard.self,
        BashPlusCard.id: BashPlusCard.self,
        // 普通卡牌
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
    
    /// 根据稀有度获取卡牌（不包含升级版）
    public static func cards(ofRarity rarity: CardRarity) -> [any CardDefinition.Type] {
        definitions.values.filter { $0.rarity == rarity && !$0.isUpgraded }
    }
    
    /// 根据类型获取卡牌（不包含升级版）
    public static func cards(ofType type: CardType) -> [any CardDefinition.Type] {
        definitions.values.filter { $0.cardType == type && !$0.isUpgraded }
    }
    
    /// 获取卡牌的升级版（如果有）
    public static func getUpgradedVersion(_ id: String) -> (any CardDefinition.Type)? {
        guard let definition = get(id),
              let upgradedId = definition.upgradedVersionId else {
            return nil
        }
        return get(upgradedId)
    }
}
```

### Card 结构体修改

```swift
// ═══════════════════════════════════════════════════════════════
// Card.swift - 修改后的卡牌实例
// ═══════════════════════════════════════════════════════════════

/// 卡牌实例（运行时）
public struct Card: Identifiable, Sendable {
    public let id: String
    
    /// 卡牌定义 ID（新增）
    public let definitionId: String
    
    /// 向后兼容：保留 kind（将在后续版本删除）
    @available(*, deprecated, message: "Use definitionId instead")
    public let kind: CardKind?
    
    /// 从 CardDefinition 获取属性
    public var definition: (any CardDefinition.Type)? {
        CardRegistry.get(definitionId)
    }
    
    public var cost: Int {
        definition?.cost ?? kind?.cost ?? 0
    }
    
    public var displayName: String {
        definition?.displayName ?? kind?.displayName ?? "Unknown"
    }
    
    public var description: String {
        definition?.description ?? ""
    }
    
    public var baseDamage: Int? {
        definition?.baseDamage
    }
    
    public var baseBlock: Int? {
        definition?.baseBlock
    }
    
    // 新的初始化方法（推荐）
    public init(id: String, definitionId: String) {
        self.id = id
        self.definitionId = definitionId
        self.kind = nil
    }
    
    // 向后兼容的初始化方法（将废弃）
    public init(id: String, kind: CardKind) {
        self.id = id
        self.kind = kind
        // 将 CardKind 映射到 definitionId
        self.definitionId = kind.rawValue
    }
}
```

### BattleEngine 重构

```swift
// 在 BattleEngine 中使用协议驱动的卡牌效果执行
private func executeCardEffect(_ card: Card) {
    // 优先使用 CardDefinition
    if let definition = CardRegistry.get(card.definitionId) {
        executeCardDefinition(definition, card: card)
        return
    }
    
    // 回退到旧的 switch 方式（向后兼容）
    if let kind = card.kind {
        executeCardKind(kind, card: card)
    }
}

private func executeCardDefinition(_ definition: any CardDefinition.Type, card: Card) {
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
        let entity = resolveTarget(target, forDamage: true)
        let finalDamage = DamageCalculator.calculate(
            baseDamage: baseDamage,
            attacker: state.player,
            defender: entity
        )
        let (dealt, blocked) = entity == state.enemy 
            ? state.enemy.takeDamage(finalDamage)
            : state.player.takeDamage(finalDamage)
        battleStats.totalDamageDealt += dealt
        emit(.damageDealt(
            source: state.player.name,
            target: entity.name,
            amount: dealt,
            blocked: blocked
        ))
        
    case .gainBlock(let target, let amount):
        if target == .`self` {
            state.player.gainBlock(amount)
            battleStats.totalBlockGained += amount
            emit(.blockGained(target: state.player.name, amount: amount))
        }
        
    case .applyStatus(let target, let statusId, let stacks):
        let entity = resolveTarget(target, forDamage: false)
        applyStatusById(to: &entity, statusId: statusId, stacks: stacks)
        
    case .drawCards(let count):
        drawCards(count)
        
    case .gainEnergy(let amount):
        state.energy += amount
        emit(.energyGained(amount: amount))
        
    case .heal(let target, let amount):
        // 实现治疗效果
        break
        
    case .discardCards(let count):
        // 实现弃牌效果
        break
        
    case .exhaust:
        // 消耗卡牌，不进入弃牌堆
        break
    }
}

/// 根据状态 ID 施加状态（临时实现，P2 会重构）
private func applyStatusById(to entity: inout Entity, statusId: String, stacks: Int) {
    switch statusId {
    case "vulnerable":
        entity.vulnerable += stacks
        emit(.statusApplied(target: entity.name, effect: "易伤", stacks: stacks))
    case "weak":
        entity.weak += stacks
        emit(.statusApplied(target: entity.name, effect: "虚弱", stacks: stacks))
    case "strength":
        entity.strength += stacks
        emit(.statusApplied(target: entity.name, effect: "力量", stacks: stacks))
    default:
        break
    }
}
```

### 实施步骤（修订版）

| 步骤 | 内容 | 复杂度 | 预计时间 |
|------|------|--------|----------|
| P1.1 | 创建 `DamageCalculator`（从 BattleEngine 提取） | ⭐ | 10分钟 |
| P1.2 | 创建 `CardEffectResult` 枚举 | ⭐ | 15分钟 |
| P1.3 | 创建 `CardDefinition` 协议和相关类型 | ⭐ | 20分钟 |
| P1.4 | 实现基础卡牌（Strike, Defend, Bash）及升级版 | ⭐ | 30分钟 |
| P1.5 | 实现其他现有卡牌（PommelStrike, ShrugItOff, Inflame, Clothesline） | ⭐ | 30分钟 |
| P1.6 | 创建 `CardRegistry` 注册表 | ⭐ | 15分钟 |
| P1.7 | 修改 `Card` 结构体添加 `definitionId` | ⭐⭐ | 20分钟 |
| P1.8 | 重构 `BattleEngine.executeCardEffect()` | ⭐⭐ | 40分钟 |
| P1.9 | 更新 `StarterDeck` 使用新的卡牌系统 | ⭐ | 10分钟 |
| P1.10 | 更新 UI 层（EventFormatter, BattleScreen）获取卡牌信息 | ⭐ | 20分钟 |
| P1.11 | 添加 2 张新卡牌验证扩展性 | ⭐ | 20分钟 |
| **总计** | | | **~3.5小时** |

### 验收标准

- [ ] `DamageCalculator` 从 BattleEngine 提取成功
- [ ] 所有现有 7 张卡牌迁移到协议驱动模式
- [ ] 3 张基础卡牌有升级版实现
- [ ] `CardRegistry` 支持按 ID、稀有度、类型查询
- [ ] `Card` 结构体同时支持新旧两种初始化方式
- [ ] BattleEngine 优先使用 CardDefinition，回退到 CardKind
- [ ] 添加 2 张新卡牌验证扩展性
- [ ] 所有测试通过
- [ ] `swift build` 成功

---

## P2: 状态效果系统协议化 ⭐⭐

### 目标
- 将状态效果（易伤、虚弱、力量等）抽象为协议
- 支持添加新的状态效果（中毒、敏捷、脆弱等）
- 统一状态效果的触发时机
- **重构 Entity，使用 StatusContainer 替代硬编码字段**

### 新架构设计

```
Sources/GameCore/Status/
├── StatusEffectDefinition.swift  # 状态效果定义协议
├── StatusContainer.swift         # 状态容器（替代 Entity 中的硬编码）
├── StatusRegistry.swift          # 状态注册表
├── StatusType.swift              # 状态类型枚举（P1 中使用字符串，这里提供枚举）
└── Effects/
    ├── VulnerableEffect.swift    # 易伤：受到伤害 +50%
    ├── WeakEffect.swift          # 虚弱：造成伤害 -25%
    ├── StrengthEffect.swift      # 力量：攻击伤害 +N
    ├── DexterityEffect.swift     # 敏捷：格挡 +N
    ├── FrailEffect.swift         # 脆弱：获得格挡 -25%
    ├── PoisonEffect.swift        # 中毒：回合结束受到 N 伤害
    └── ...
```

### 协议设计

```swift
// ═══════════════════════════════════════════════════════════════
// StatusEffectDefinition.swift - 状态效果定义协议
// ═══════════════════════════════════════════════════════════════

/// 状态效果定义协议
/// 每种状态效果实现此协议，定义其行为
public protocol StatusEffectDefinition: Sendable {
    /// 状态唯一标识符（如 "vulnerable", "weak"）
    static var id: String { get }
    
    /// 显示名称
    static var displayName: String { get }
    
    /// 显示图标
    static var icon: String { get }
    
    /// 是否为正面效果（Buff vs Debuff）
    static var isPositive: Bool { get }
    
    /// 是否随时间递减（每回合 -1）
    static var decaysOverTime: Bool { get }
    
    /// 递减时机
    static var decayTiming: StatusDecayTiming { get }
    
    // ═══════════════════════════════════════════════════════════
    // 伤害修正
    // ═══════════════════════════════════════════════════════════
    
    /// 修正造成的伤害（作为攻击者）
    /// - Parameters:
    ///   - damage: 原始伤害
    ///   - stacks: 状态层数
    /// - Returns: 修正后的伤害
    static func modifyOutgoingDamage(_ damage: Int, stacks: Int) -> Int
    
    /// 修正受到的伤害（作为防御者）
    static func modifyIncomingDamage(_ damage: Int, stacks: Int) -> Int
    
    /// 修正获得的格挡
    static func modifyBlock(_ block: Int, stacks: Int) -> Int
    
    // ═══════════════════════════════════════════════════════════
    // 触发效果
    // ═══════════════════════════════════════════════════════════
    
    /// 回合开始时触发
    /// - Returns: (是否消耗层数, 产生的事件)
    static func onTurnStart(stacks: Int, entity: Entity) -> (consumeStacks: Int, events: [BattleEvent])
    
    /// 回合结束时触发
    static func onTurnEnd(stacks: Int, entity: Entity) -> (consumeStacks: Int, events: [BattleEvent])
}

/// 状态递减时机
public enum StatusDecayTiming: Sendable {
    case turnStart   // 回合开始时递减
    case turnEnd     // 回合结束时递减
    case never       // 永不递减（永久效果）
}

// 提供默认实现
extension StatusEffectDefinition {
    public static var decayTiming: StatusDecayTiming {
        decaysOverTime ? .turnStart : .never
    }
    
    public static func modifyOutgoingDamage(_ damage: Int, stacks: Int) -> Int { damage }
    public static func modifyIncomingDamage(_ damage: Int, stacks: Int) -> Int { damage }
    public static func modifyBlock(_ block: Int, stacks: Int) -> Int { block }
    
    public static func onTurnStart(stacks: Int, entity: Entity) -> (consumeStacks: Int, events: [BattleEvent]) {
        (0, [])
    }
    
    public static func onTurnEnd(stacks: Int, entity: Entity) -> (consumeStacks: Int, events: [BattleEvent]) {
        (0, [])
    }
}
```

```swift
// ═══════════════════════════════════════════════════════════════
// StatusContainer.swift - 状态容器
// ═══════════════════════════════════════════════════════════════

/// 状态容器
/// 管理实体的所有状态效果
public struct StatusContainer: Sendable, Equatable {
    /// 状态存储：statusId -> stacks
    private var statuses: [String: Int] = [:]
    
    public init() {}
    
    /// 获取状态层数
    public func getStacks(_ statusId: String) -> Int {
        statuses[statusId] ?? 0
    }
    
    /// 施加状态
    public mutating func apply(_ statusId: String, stacks: Int) {
        guard stacks != 0 else { return }
        statuses[statusId, default: 0] += stacks
        // 确保不为负数
        if statuses[statusId]! <= 0 {
            statuses.removeValue(forKey: statusId)
        }
    }
    
    /// 设置状态层数
    public mutating func set(_ statusId: String, stacks: Int) {
        if stacks <= 0 {
            statuses.removeValue(forKey: statusId)
        } else {
            statuses[statusId] = stacks
        }
    }
    
    /// 移除状态
    public mutating func remove(_ statusId: String) {
        statuses.removeValue(forKey: statusId)
    }
    
    /// 获取所有状态
    public var allStatuses: [(id: String, stacks: Int)] {
        statuses.map { ($0.key, $0.value) }.sorted { $0.id < $1.id }
    }
    
    /// 是否有任何状态
    public var hasAnyStatus: Bool {
        !statuses.isEmpty
    }
    
    /// 回合开始时处理
    public mutating func tickTurnStart() -> [BattleEvent] {
        var events: [BattleEvent] = []
        var toRemove: [String] = []
        
        for (statusId, stacks) in statuses {
            guard let definition = StatusRegistry.get(statusId) else { continue }
            
            // 递减
            if definition.decaysOverTime && definition.decayTiming == .turnStart {
                statuses[statusId]! -= 1
                if statuses[statusId]! <= 0 {
                    toRemove.append(statusId)
                }
            }
        }
        
        for statusId in toRemove {
            statuses.removeValue(forKey: statusId)
            if let definition = StatusRegistry.get(statusId) {
                events.append(.statusExpired(target: "", effect: definition.displayName))
            }
        }
        
        return events
    }
    
    /// 回合结束时处理
    public mutating func tickTurnEnd() -> [BattleEvent] {
        // 类似 tickTurnStart，但检查 .turnEnd 时机
        var events: [BattleEvent] = []
        // ... 实现类似逻辑
        return events
    }
}
```

### 状态效果实现示例

```swift
// ═══════════════════════════════════════════════════════════════
// VulnerableEffect.swift - 易伤
// ═══════════════════════════════════════════════════════════════

/// 易伤：受到伤害 +50%
public struct VulnerableEffect: StatusEffectDefinition {
    public static let id = "vulnerable"
    public static let displayName = "易伤"
    public static let icon = "💔"
    public static let isPositive = false
    public static let decaysOverTime = true
    
    public static func modifyIncomingDamage(_ damage: Int, stacks: Int) -> Int {
        guard stacks > 0 else { return damage }
        return Int(Double(damage) * 1.5)  // +50%
    }
}

/// 虚弱：造成伤害 -25%
public struct WeakEffect: StatusEffectDefinition {
    public static let id = "weak"
    public static let displayName = "虚弱"
    public static let icon = "💧"
    public static let isPositive = false
    public static let decaysOverTime = true
    
    public static func modifyOutgoingDamage(_ damage: Int, stacks: Int) -> Int {
        guard stacks > 0 else { return damage }
        return Int(Double(damage) * 0.75)  // -25%
    }
}

/// 力量：攻击伤害 +N
public struct StrengthEffect: StatusEffectDefinition {
    public static let id = "strength"
    public static let displayName = "力量"
    public static let icon = "💪"
    public static let isPositive = true
    public static let decaysOverTime = false  // 永久效果
    
    public static func modifyOutgoingDamage(_ damage: Int, stacks: Int) -> Int {
        damage + stacks
    }
}

/// 敏捷：格挡 +N
public struct DexterityEffect: StatusEffectDefinition {
    public static let id = "dexterity"
    public static let displayName = "敏捷"
    public static let icon = "🏃"
    public static let isPositive = true
    public static let decaysOverTime = false
    
    public static func modifyBlock(_ block: Int, stacks: Int) -> Int {
        block + stacks
    }
}

/// 中毒：回合结束受到 N 伤害，然后层数 -1
public struct PoisonEffect: StatusEffectDefinition {
    public static let id = "poison"
    public static let displayName = "中毒"
    public static let icon = "🧪"
    public static let isPositive = false
    public static let decaysOverTime = true
    public static let decayTiming: StatusDecayTiming = .turnEnd
    
    public static func onTurnEnd(stacks: Int, entity: Entity) -> (consumeStacks: Int, events: [BattleEvent]) {
        guard stacks > 0 else { return (0, []) }
        // 造成等于层数的伤害
        let damage = stacks
        return (1, [.damageDealt(source: "中毒", target: entity.name, amount: damage, blocked: 0)])
    }
}
```

### Entity 修改

```swift
// ═══════════════════════════════════════════════════════════════
// Entity.swift - 使用 StatusContainer
// ═══════════════════════════════════════════════════════════════

public struct Entity: Sendable {
    public let id: String
    public let name: String
    public let maxHP: Int
    public var currentHP: Int
    public var block: Int
    
    /// 状态效果容器（新增）
    public var statuses: StatusContainer = StatusContainer()
    
    /// 敌人定义 ID（替代 kind）
    public let enemyDefinitionId: String?
    
    /// 当前意图（仅敌人使用）
    public var intent: EnemyIntent = .unknown
    
    // ═══════════════════════════════════════════════════════════
    // 兼容性属性（使用 StatusContainer 实现）
    // ═══════════════════════════════════════════════════════════
    
    public var vulnerable: Int {
        get { statuses.getStacks("vulnerable") }
        set { 
            let diff = newValue - vulnerable
            if diff != 0 { statuses.apply("vulnerable", stacks: diff) }
        }
    }
    
    public var weak: Int {
        get { statuses.getStacks("weak") }
        set {
            let diff = newValue - weak
            if diff != 0 { statuses.apply("weak", stacks: diff) }
        }
    }
    
    public var strength: Int {
        get { statuses.getStacks("strength") }
        set {
            let diff = newValue - strength
            if diff != 0 { statuses.apply("strength", stacks: diff) }
        }
    }
    
    public var isAlive: Bool { currentHP > 0 }
    
    public var hasAnyStatus: Bool { statuses.hasAnyStatus }
    
    // ... 其余方法保持不变，使用 statuses 替代直接字段访问
}
```

### DamageCalculator 重构

```swift
// 使用 StatusRegistry 进行伤害修正
public enum DamageCalculator {
    
    public static func calculate(
        baseDamage: Int,
        attacker: Entity,
        defender: Entity
    ) -> Int {
        var damage = baseDamage
        
        // 应用攻击者的所有状态修正
        for (statusId, stacks) in attacker.statuses.allStatuses {
            if let definition = StatusRegistry.get(statusId) {
                damage = definition.modifyOutgoingDamage(damage, stacks: stacks)
            }
        }
        
        // 应用防御者的所有状态修正
        for (statusId, stacks) in defender.statuses.allStatuses {
            if let definition = StatusRegistry.get(statusId) {
                damage = definition.modifyIncomingDamage(damage, stacks: stacks)
            }
        }
        
        return max(0, damage)
    }
}
```

### 实施步骤（修订版）

| 步骤 | 内容 | 复杂度 | 预计时间 |
|------|------|--------|----------|
| P2.1 | 创建 `StatusEffectDefinition` 协议 | ⭐ | 20分钟 |
| P2.2 | 创建 `StatusContainer` 容器 | ⭐⭐ | 30分钟 |
| P2.3 | 创建 `StatusRegistry` 注册表 | ⭐ | 15分钟 |
| P2.4 | 实现 `VulnerableEffect`, `WeakEffect`, `StrengthEffect` | ⭐ | 20分钟 |
| P2.5 | 重构 `Entity` 使用 `StatusContainer` | ⭐⭐ | 40分钟 |
| P2.6 | 重构 `DamageCalculator` 使用 `StatusRegistry` | ⭐⭐ | 30分钟 |
| P2.7 | 重构 `BattleEngine` 状态相关逻辑 | ⭐⭐ | 40分钟 |
| P2.8 | 实现 `DexterityEffect`（敏捷）验证格挡修正 | ⭐ | 15分钟 |
| P2.9 | 实现 `PoisonEffect`（中毒）验证回合结束触发 | ⭐ | 20分钟 |
| P2.10 | 更新 UI 层状态显示 | ⭐ | 20分钟 |
| **总计** | | | **~4小时** |

### 验收标准

- [ ] `StatusContainer` 正确管理所有状态
- [ ] `Entity` 的 `vulnerable`, `weak`, `strength` 属性正常工作（兼容性）
- [ ] `DamageCalculator` 使用 `StatusRegistry` 进行伤害修正
- [ ] 易伤效果：受到伤害 +50%
- [ ] 虚弱效果：造成伤害 -25%
- [ ] 力量效果：攻击伤害 +N
- [ ] 敏捷效果：获得格挡 +N
- [ ] 中毒效果：回合结束造成 N 伤害
- [ ] 状态递减正确工作
- [ ] 所有测试通过
- [ ] `swift build` 成功

---

## P3: 敌人系统统一 ⭐⭐

### 目标
- 将 `EnemyKind` + `EnemyData` + `EnemyAI` 合并为统一的 `EnemyDefinition`
- 每个敌人是一个独立的结构体，包含数据和行为
- 添加新敌人只需创建新结构体并注册

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
│  └── decideIntent()                   │
└───────────────────────────────────────┘
        │
添加新敌人只需创建 1 个结构体 + 注册
```

### 新架构设计

```
Sources/GameCore/Enemies/
├── EnemyDefinition.swift         # 敌人定义协议
├── EnemyRegistry.swift           # 敌人注册表
├── EnemyPool.swift               # 敌人池（保留，使用注册表）
├── EnemyIntent.swift             # 意图类型（保留）
├── Definitions/
│   ├── Act1/
│   │   ├── JawWormEnemy.swift    # 下颚虫
│   │   ├── CultistEnemy.swift    # 信徒
│   │   ├── LouseEnemies.swift    # 绿虱子、红虱子
│   │   └── SlimeEnemies.swift    # 酸液史莱姆
│   ├── Act1Elites/
│   │   └── ...                   # 精英敌人
│   └── Act1Boss/
│       └── ...                   # Boss
└── [已删除] EnemyKind.swift, EnemyData.swift, EnemyAI.swift, EnemyBehaviors.swift
```

### 协议设计

```swift
// ═══════════════════════════════════════════════════════════════
// EnemyDefinition.swift - 敌人定义协议
// ═══════════════════════════════════════════════════════════════

/// 敌人定义协议
/// 统一敌人的数据和行为
public protocol EnemyDefinition: Sendable {
    /// 敌人唯一标识符（如 "jaw_worm", "cultist"）
    static var id: String { get }
    
    /// 显示名称
    static var displayName: String { get }
    
    /// HP 范围
    static var hpRange: ClosedRange<Int> { get }
    
    /// 基础攻击力（用于默认攻击意图）
    static var baseAttack: Int { get }
    
    /// 敌人描述
    static var description: String { get }
    
    /// 敌人类型
    static var enemyType: EnemyType { get }
    
    /// 决定下一个意图
    /// - Parameters:
    ///   - enemy: 敌人实体（当前状态）
    ///   - player: 玩家实体（当前状态）
    ///   - turn: 当前回合数
    ///   - lastIntent: 上一个意图（用于避免连续相同行动）
    ///   - rng: 随机数生成器
    /// - Returns: 敌人意图
    static func decideIntent(
        enemy: Entity,
        player: Entity,
        turn: Int,
        lastIntent: EnemyIntent?,
        rng: inout SeededRNG
    ) -> EnemyIntent
    
    /// 生成敌人实体
    static func spawn(rng: inout SeededRNG) -> Entity
}

/// 敌人类型
public enum EnemyType: String, Sendable {
    case normal = "普通"
    case elite = "精英"
    case boss = "Boss"
}

// 提供默认实现
extension EnemyDefinition {
    public static var enemyType: EnemyType { .normal }
    
    public static func spawn(rng: inout SeededRNG) -> Entity {
        let range = hpRange
        let hp = range.lowerBound + rng.nextInt(upperBound: range.upperBound - range.lowerBound + 1)
        return Entity(
            id: UUID().uuidString,  // 唯一实例 ID
            name: displayName,
            maxHP: hp,
            enemyDefinitionId: id
        )
    }
}
```

### 敌人实现示例

```swift
// ═══════════════════════════════════════════════════════════════
// JawWormEnemy.swift - 下颚虫
// ═══════════════════════════════════════════════════════════════

/// 下颚虫
/// 行为模式：咬（11伤害）、嚎叫（+3力量）、猛扑（7伤害）
public struct JawWormEnemy: EnemyDefinition {
    public static let id = "jaw_worm"
    public static let displayName = "下颚虫"
    public static let hpRange = 40...44
    public static let baseAttack = 11
    public static let description = "凶猛的虫类敌人，会嚎叫增强自身力量"
    
    public static func decideIntent(
        enemy: Entity,
        player: Entity,
        turn: Int,
        lastIntent: EnemyIntent?,
        rng: inout SeededRNG
    ) -> EnemyIntent {
        let roll = rng.nextInt(upperBound: 100)
        let damage = baseAttack + enemy.strength
        
        if turn == 1 {
            // 第一回合 75% 咬
            return roll < 75 ? .attack(damage: damage) : .buff(name: "力量", stacks: 3)
        }
        
        // 后续回合
        if roll < 45 {
            return .attack(damage: damage)
        } else if roll < 75 {
            return .buff(name: "力量", stacks: 3)
        } else {
            // 猛扑
            return .attack(damage: 7 + enemy.strength)
        }
    }
}

/// 信徒
/// 行为模式：第一回合念咒（+3力量），后续攻击
public struct CultistEnemy: EnemyDefinition {
    public static let id = "cultist"
    public static let displayName = "信徒"
    public static let hpRange = 48...54
    public static let baseAttack = 6
    public static let description = "狂热的信徒，会通过仪式增强力量"
    
    public static func decideIntent(
        enemy: Entity,
        player: Entity,
        turn: Int,
        lastIntent: EnemyIntent?,
        rng: inout SeededRNG
    ) -> EnemyIntent {
        if turn == 1 {
            return .buff(name: "仪式", stacks: 3)
        }
        return .attack(damage: baseAttack + enemy.strength)
    }
}

/// 绿虱子
public struct LouseGreenEnemy: EnemyDefinition {
    public static let id = "louse_green"
    public static let displayName = "绿虱子"
    public static let hpRange = 11...17
    public static let baseAttack = 6
    public static let description = "小型害虫，偶尔会卷曲增强力量"
    
    public static func decideIntent(
        enemy: Entity,
        player: Entity,
        turn: Int,
        lastIntent: EnemyIntent?,
        rng: inout SeededRNG
    ) -> EnemyIntent {
        let roll = rng.nextInt(upperBound: 100)
        
        if roll < 75 {
            return .attack(damage: baseAttack + enemy.strength)
        } else {
            return .buff(name: "卷曲", stacks: 3)
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
    
    private static let definitions: [String: any EnemyDefinition.Type] = [
        // Act 1 普通敌人
        JawWormEnemy.id: JawWormEnemy.self,
        CultistEnemy.id: CultistEnemy.self,
        LouseGreenEnemy.id: LouseGreenEnemy.self,
        LouseRedEnemy.id: LouseRedEnemy.self,
        SlimeMediumAcidEnemy.id: SlimeMediumAcidEnemy.self,
        // ... 更多敌人
    ]
    
    /// 根据 ID 获取敌人定义
    public static func get(_ id: String) -> (any EnemyDefinition.Type)? {
        definitions[id]
    }
    
    /// 获取所有敌人 ID
    public static var allEnemyIds: [String] {
        Array(definitions.keys)
    }
    
    /// 根据类型获取敌人
    public static func enemies(ofType type: EnemyType) -> [any EnemyDefinition.Type] {
        definitions.values.filter { $0.enemyType == type }
    }
    
    /// 生成敌人实体
    public static func spawn(_ id: String, rng: inout SeededRNG) -> Entity? {
        guard let definition = get(id) else { return nil }
        return definition.spawn(rng: &rng)
    }
}
```

### EnemyPool 重构

```swift
// ═══════════════════════════════════════════════════════════════
// EnemyPool.swift - 使用 EnemyRegistry
// ═══════════════════════════════════════════════════════════════

/// 第一章敌人池
public enum Act1EnemyPool {
    /// 弱敌人 ID 列表
    public static let weak: [String] = [
        JawWormEnemy.id,
        CultistEnemy.id,
        LouseGreenEnemy.id,
        LouseRedEnemy.id
    ]
    
    /// 中等敌人 ID 列表
    public static let medium: [String] = [
        SlimeMediumAcidEnemy.id
    ]
    
    /// 所有敌人
    public static let all: [String] = weak + medium
    
    /// 随机选择弱敌人并生成
    public static func spawnRandomWeak(rng: inout SeededRNG) -> Entity {
        let index = rng.nextInt(upperBound: weak.count)
        let id = weak[index]
        return EnemyRegistry.spawn(id, rng: &rng)!
    }
    
    /// 随机选择任意敌人并生成
    public static func spawnRandomAny(rng: inout SeededRNG) -> Entity {
        let index = rng.nextInt(upperBound: all.count)
        let id = all[index]
        return EnemyRegistry.spawn(id, rng: &rng)!
    }
}
```

### BattleEngine 修改

```swift
// 在 BattleEngine 中使用 EnemyRegistry 获取敌人 AI
private func decideEnemyIntent() {
    guard let definitionId = state.enemy.enemyDefinitionId,
          let definition = EnemyRegistry.get(definitionId) else {
        // 回退到默认攻击
        state.enemy.intent = .attack(damage: 6)
        return
    }
    
    let intent = definition.decideIntent(
        enemy: state.enemy,
        player: state.player,
        turn: state.turn,
        lastIntent: state.enemy.intent,
        rng: &rng
    )
    state.enemy.intent = intent
}
```

### 实施步骤（修订版）

| 步骤 | 内容 | 复杂度 | 预计时间 |
|------|------|--------|----------|
| P3.1 | 创建 `EnemyDefinition` 协议 | ⭐ | 15分钟 |
| P3.2 | 创建 `EnemyRegistry` 注册表 | ⭐ | 15分钟 |
| P3.3 | 实现 `JawWormEnemy` | ⭐ | 15分钟 |
| P3.4 | 实现 `CultistEnemy`, `LouseGreenEnemy`, `LouseRedEnemy` | ⭐ | 30分钟 |
| P3.5 | 实现 `SlimeMediumAcidEnemy` | ⭐ | 15分钟 |
| P3.6 | 修改 `Entity` 添加 `enemyDefinitionId` | ⭐ | 15分钟 |
| P3.7 | 重构 `EnemyPool` 使用注册表 | ⭐ | 20分钟 |
| P3.8 | 重构 `BattleEngine` 使用 `EnemyRegistry` | ⭐⭐ | 30分钟 |
| P3.9 | 验证所有敌人行为正确 | ⭐ | 20分钟 |
| P3.10 | 删除旧代码（`EnemyKind`, `EnemyData`, `EnemyAI`, `EnemyBehaviors`） | ⭐ | 10分钟 |
| P3.11 | 添加 2 个新敌人验证扩展性（如 `FungiBeastEnemy`, `GremlinEnemy`） | ⭐ | 30分钟 |
| **总计** | | | **~3.5小时** |

### 验收标准

- [ ] 所有 5 种现有敌人迁移到 `EnemyDefinition` 协议
- [ ] `EnemyRegistry` 正确管理所有敌人定义
- [ ] `EnemyPool` 使用注册表生成敌人
- [ ] `BattleEngine` 使用 `EnemyRegistry` 获取敌人 AI
- [ ] 每种敌人的行为与原来一致
- [ ] 旧代码已删除：`EnemyKind.swift`, `EnemyData.swift`, `EnemyAI.swift`, `EnemyBehaviors.swift`
- [ ] 添加 2 个新敌人验证扩展性
- [ ] 所有测试通过
- [ ] `swift build` 成功

---

## P4: 遗物系统设计 ⭐

### 目标
- 设计遗物系统协议
- 支持多种触发时机（战斗开始、回合开始、打牌时等）
- 遗物与战斗引擎深度集成

### 新架构设计

```
Sources/GameCore/Relics/
├── RelicDefinition.swift         # 遗物定义协议
├── RelicTrigger.swift            # 触发时机枚举
├── RelicManager.swift            # 遗物管理器
├── RelicRegistry.swift           # 遗物注册表
└── Definitions/
    ├── StarterRelics.swift       # 起始遗物
    │   ├── BurningBlood          # 燃烧之血：战斗结束恢复 6 HP
    │   └── ...
    ├── CommonRelics.swift        # 普通遗物
    │   ├── Vajra                 # 金刚杵：+1 力量
    │   ├── Lantern               # 灯笼：战斗开始 +1 能量
    │   └── ...
    └── BossRelics.swift          # Boss 遗物
```

### 协议设计

```swift
// ═══════════════════════════════════════════════════════════════
// RelicDefinition.swift - 遗物定义协议
// ═══════════════════════════════════════════════════════════════

/// 遗物定义协议
public protocol RelicDefinition: Sendable {
    /// 遗物唯一标识符
    static var id: String { get }
    
    /// 显示名称
    static var displayName: String { get }
    
    /// 遗物描述
    static var description: String { get }
    
    /// 遗物稀有度
    static var rarity: RelicRarity { get }
    
    /// 显示图标
    static var icon: String { get }
    
    /// 该遗物关注的触发时机
    static var triggers: [RelicTrigger] { get }
    
    /// 处理触发事件
    /// - Parameters:
    ///   - trigger: 触发类型
    ///   - context: 触发上下文
    /// - Returns: 遗物效果结果
    static func onTrigger(_ trigger: RelicTrigger, context: RelicTriggerContext) -> RelicEffectResult
}

/// 遗物稀有度
public enum RelicRarity: String, Sendable {
    case starter = "起始"
    case common = "普通"
    case uncommon = "罕见"
    case rare = "稀有"
    case boss = "Boss"
    case event = "事件"
}

/// 遗物触发时机
public enum RelicTrigger: String, Sendable, Equatable {
    // 战斗相关
    case battleStart = "battle_start"      // 战斗开始
    case battleEnd = "battle_end"          // 战斗结束
    case turnStart = "turn_start"          // 回合开始
    case turnEnd = "turn_end"              // 回合结束
    
    // 卡牌相关
    case cardPlayed = "card_played"        // 打出卡牌
    case cardDrawn = "card_drawn"          // 抽牌
    case cardExhausted = "card_exhausted"  // 消耗卡牌
    
    // 伤害相关
    case damageDealt = "damage_dealt"      // 造成伤害
    case damageTaken = "damage_taken"      // 受到伤害
    case blockGained = "block_gained"      // 获得格挡
    
    // 状态相关
    case enemyKilled = "enemy_killed"      // 击杀敌人
    case hpLost = "hp_lost"                // 失去 HP
    case goldGained = "gold_gained"        // 获得金币
    
    // 冒险相关
    case roomEntered = "room_entered"      // 进入房间
    case runStart = "run_start"            // 冒险开始
}

/// 遗物触发上下文
public struct RelicTriggerContext: Sendable {
    public let player: Entity
    public let enemy: Entity?
    public let battleState: BattleState?
    public let runState: RunState?
    
    // 可选的事件相关数据
    public let cardPlayed: Card?
    public let damageAmount: Int?
    public let blockAmount: Int?
    
    public init(
        player: Entity,
        enemy: Entity? = nil,
        battleState: BattleState? = nil,
        runState: RunState? = nil,
        cardPlayed: Card? = nil,
        damageAmount: Int? = nil,
        blockAmount: Int? = nil
    ) {
        self.player = player
        self.enemy = enemy
        self.battleState = battleState
        self.runState = runState
        self.cardPlayed = cardPlayed
        self.damageAmount = damageAmount
        self.blockAmount = blockAmount
    }
}

/// 遗物效果结果
public enum RelicEffectResult: Sendable {
    case none                                      // 无效果
    case heal(amount: Int)                         // 治疗
    case gainEnergy(amount: Int)                   // 获得能量
    case gainBlock(amount: Int)                    // 获得格挡
    case drawCards(count: Int)                     // 抽牌
    case applyStatus(statusId: String, stacks: Int) // 施加状态
    case gainGold(amount: Int)                     // 获得金币
    case multiple([RelicEffectResult])             // 多个效果
}
```

### 遗物实现示例

```swift
// ═══════════════════════════════════════════════════════════════
// StarterRelics.swift - 起始遗物
// ═══════════════════════════════════════════════════════════════

/// 燃烧之血（铁甲战士起始遗物）
/// 效果：战斗结束时恢复 6 HP
public struct BurningBloodRelic: RelicDefinition {
    public static let id = "burning_blood"
    public static let displayName = "燃烧之血"
    public static let description = "战斗结束时恢复 6 点生命值"
    public static let rarity: RelicRarity = .starter
    public static let icon = "🔥"
    public static let triggers: [RelicTrigger] = [.battleEnd]
    
    public static func onTrigger(_ trigger: RelicTrigger, context: RelicTriggerContext) -> RelicEffectResult {
        guard trigger == .battleEnd else { return .none }
        return .heal(amount: 6)
    }
}

/// 金刚杵
/// 效果：战斗开始时获得 1 点力量
public struct VajraRelic: RelicDefinition {
    public static let id = "vajra"
    public static let displayName = "金刚杵"
    public static let description = "战斗开始时获得 1 点力量"
    public static let rarity: RelicRarity = .common
    public static let icon = "💎"
    public static let triggers: [RelicTrigger] = [.battleStart]
    
    public static func onTrigger(_ trigger: RelicTrigger, context: RelicTriggerContext) -> RelicEffectResult {
        guard trigger == .battleStart else { return .none }
        return .applyStatus(statusId: "strength", stacks: 1)
    }
}

/// 灯笼
/// 效果：战斗开始时获得 1 点能量
public struct LanternRelic: RelicDefinition {
    public static let id = "lantern"
    public static let displayName = "灯笼"
    public static let description = "战斗开始时获得 1 点能量"
    public static let rarity: RelicRarity = .common
    public static let icon = "🏮"
    public static let triggers: [RelicTrigger] = [.battleStart]
    
    public static func onTrigger(_ trigger: RelicTrigger, context: RelicTriggerContext) -> RelicEffectResult {
        guard trigger == .battleStart else { return .none }
        return .gainEnergy(amount: 1)
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
    private var relicIds: [String] = []
    
    public init() {}
    
    /// 添加遗物
    public mutating func add(_ relicId: String) {
        guard !relicIds.contains(relicId) else { return }
        relicIds.append(relicId)
    }
    
    /// 移除遗物
    public mutating func remove(_ relicId: String) {
        relicIds.removeAll { $0 == relicId }
    }
    
    /// 是否拥有指定遗物
    public func has(_ relicId: String) -> Bool {
        relicIds.contains(relicId)
    }
    
    /// 获取所有遗物
    public var allRelics: [any RelicDefinition.Type] {
        relicIds.compactMap { RelicRegistry.get($0) }
    }
    
    /// 触发所有关注指定事件的遗物
    public func trigger(_ trigger: RelicTrigger, context: RelicTriggerContext) -> [RelicEffectResult] {
        var results: [RelicEffectResult] = []
        
        for relicId in relicIds {
            guard let definition = RelicRegistry.get(relicId) else { continue }
            
            // 只触发关注此事件的遗物
            guard definition.triggers.contains(trigger) else { continue }
            
            let result = definition.onTrigger(trigger, context: context)
            if case .none = result {
                continue
            }
            results.append(result)
        }
        
        return results
    }
}
```

### BattleEngine 集成

```swift
// 在 BattleEngine 中添加遗物触发点
public func startBattle() {
    events.removeAll()
    emit(.battleStarted)
    
    // 触发战斗开始遗物
    let context = RelicTriggerContext(
        player: state.player,
        enemy: state.enemy,
        battleState: state
    )
    let relicResults = relicManager.trigger(.battleStart, context: context)
    for result in relicResults {
        applyRelicEffect(result)
    }
    
    startNewTurn()
}

private func applyRelicEffect(_ result: RelicEffectResult) {
    switch result {
    case .none:
        break
    case .heal(let amount):
        state.player.currentHP = min(state.player.maxHP, state.player.currentHP + amount)
        emit(.healed(target: state.player.name, amount: amount))
    case .gainEnergy(let amount):
        state.energy += amount
        emit(.energyGained(amount: amount))
    case .gainBlock(let amount):
        state.player.gainBlock(amount)
        emit(.blockGained(target: state.player.name, amount: amount))
    case .drawCards(let count):
        drawCards(count)
    case .applyStatus(let statusId, let stacks):
        state.player.statuses.apply(statusId, stacks: stacks)
        if let definition = StatusRegistry.get(statusId) {
            emit(.statusApplied(target: state.player.name, effect: definition.displayName, stacks: stacks))
        }
    case .gainGold(let amount):
        // 需要 RunState 支持
        break
    case .multiple(let effects):
        for effect in effects {
            applyRelicEffect(effect)
        }
    }
}
```

### 实施步骤

| 步骤 | 内容 | 复杂度 | 预计时间 |
|------|------|--------|----------|
| P4.1 | 创建 `RelicDefinition` 协议和相关类型 | ⭐ | 25分钟 |
| P4.2 | 创建 `RelicTrigger` 枚举 | ⭐ | 10分钟 |
| P4.3 | 创建 `RelicManager` 管理器 | ⭐⭐ | 30分钟 |
| P4.4 | 创建 `RelicRegistry` 注册表 | ⭐ | 15分钟 |
| P4.5 | 实现 `BurningBloodRelic`（燃烧之血） | ⭐ | 15分钟 |
| P4.6 | 实现 `VajraRelic`（金刚杵） | ⭐ | 10分钟 |
| P4.7 | 实现 `LanternRelic`（灯笼） | ⭐ | 10分钟 |
| P4.8 | 修改 `RunState` 添加 `RelicManager` | ⭐ | 15分钟 |
| P4.9 | 修改 `BattleEngine` 添加遗物触发点 | ⭐⭐ | 40分钟 |
| P4.10 | 添加遗物 UI 显示 | ⭐ | 25分钟 |
| P4.11 | 验证所有遗物效果正确 | ⭐ | 20分钟 |
| **总计** | | | **~3.5小时** |

### 验收标准

- [ ] `RelicDefinition` 协议完整定义
- [ ] `RelicManager` 正确管理遗物集合
- [ ] `RelicRegistry` 正确注册所有遗物
- [ ] 燃烧之血：战斗结束恢复 6 HP
- [ ] 金刚杵：战斗开始 +1 力量
- [ ] 灯笼：战斗开始 +1 能量
- [ ] `BattleEngine` 正确触发遗物效果
- [ ] 遗物在 UI 中正确显示
- [ ] 所有测试通过
- [ ] `swift build` 成功

---

## ⚠️ 风险与注意事项

### 1. 向后兼容性

由于这是一个破坏性重构，需要注意：
- 战绩数据中存储的 `CardKind.rawValue`，需要映射到新的 `definitionId`
- `Card` 结构体保留 `kind` 属性用于过渡期
- `Entity` 的 `vulnerable`, `weak`, `strength` 属性保留为计算属性

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

### 4. 回滚策略

如果某个阶段出现严重问题：
- P1-P3 都设计了兼容性层，可以回退到旧实现
- 建议每个阶段完成后 `git commit`

---

## 📋 检查清单

### P1 完成后检查
- [ ] `CardRegistry.get("strike")` 返回 `StrikeCard.self`
- [ ] `Card(id: "test", definitionId: "strike")` 正确工作
- [ ] BattleEngine 正确执行卡牌效果
- [ ] UI 正确显示卡牌信息
- [ ] 添加新卡牌只需 1 个新结构体 + 注册

### P2 完成后检查
- [ ] `Entity.vulnerable`, `.weak`, `.strength` 正常工作
- [ ] `StatusContainer.tick*()` 正确递减状态
- [ ] `DamageCalculator` 正确应用所有状态修正
- [ ] 中毒效果回合结束造成伤害

### P3 完成后检查
- [ ] `EnemyRegistry.get("jaw_worm")` 返回正确定义
- [ ] `EnemyPool.spawnRandomWeak()` 正确生成敌人
- [ ] 所有敌人 AI 行为与原来一致
- [ ] 旧代码已删除

### P4 完成后检查
- [ ] `RelicManager.trigger(.battleStart, ...)` 正确触发遗物
- [ ] 燃烧之血战斗结束恢复 HP
- [ ] 金刚杵战斗开始 +1 力量
- [ ] 灯笼战斗开始 +1 能量

---

## 📝 修订历史

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-01-03 | v1.0 | 初稿 |
| 2026-01-03 | v1.1 | 审视并修复设计问题：|
| | | - 添加 `DamageCalculator`（P1） |
| | | - 修复 `StatusType` 依赖问题 |
| | | - 添加卡牌升级系统支持 |
| | | - 明确 `StatusContainer` 与 Entity 集成方式 |
| | | - 移除 P4 房间系统协议化（不必要） |
| | | - 完善遗物系统设计 |
| | | - 添加详细检查清单 |

