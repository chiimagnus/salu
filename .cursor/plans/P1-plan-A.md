# P1：敌人系统 + AI - Plan A 实施方案

> 创建时间：2026-01-02
> **完成时间：2026-01-02**
> **状态：✅ 已完成**
> 预计总时间：~3 小时
> 实际总时间：~2.5 小时

---

## 📊 当前状态分析

### 已有代码结构

| 文件 | 现状 | 需修改 |
|------|------|--------|
| `Entity.swift` | 硬编码下颚虫(HP=42) | ✅ 需要修改 |
| `BattleEngine.swift` | 固定敌人攻击7点 | ✅ 需要大改 |
| `BattleState.swift` | 基础状态管理 | ✅ 需要添加敌人意图 |
| `Events.swift` | 事件定义 | ✅ 需要添加新事件 |
| `BattleScreen.swift` | 硬编码意图显示 | ✅ 需要修改 |
| `RNG.swift` | 随机数生成 | ❌ 无需修改 |

### 关键问题点

1. **敌人创建硬编码**：`createDefaultEnemy()` 只返回下颚虫
2. **敌人攻击固定**：`enemyDamage: Int = 7` 是常量
3. **无意图系统**：战斗界面硬编码 "攻击 7 伤害"
4. **无 AI 决策**：敌人回合只执行固定攻击

---

## 🎯 实施步骤

### P1.1：添加第二个敌人（信徒）⭐ 10分钟

**状态**：✅ 已完成

**修改文件**：
- `Sources/GameCore/Entity/Entity.swift`

**具体改动**：

```swift
// 在 Entity.swift 底部添加

/// 敌人类型枚举（临时方案，后续迁移到 EnemyKind.swift）
public enum EnemyType: String, Sendable {
    case jawWorm = "jaw_worm"
    case cultist = "cultist"
}

/// 创建敌人
/// - Parameters:
///   - type: 敌人类型
///   - rng: 随机数生成器（用于 HP 浮动）
/// - Returns: 敌人实体
public func createEnemy(type: EnemyType, rng: inout SeededRNG) -> Entity {
    switch type {
    case .jawWorm:
        // 下颚虫 HP: 40-44
        let hp = 40 + rng.nextInt(upperBound: 5)
        return Entity(id: "jaw_worm", name: "下颚虫", maxHP: hp)
    case .cultist:
        // 信徒 HP: 48-54
        let hp = 48 + rng.nextInt(upperBound: 7)
        return Entity(id: "cultist", name: "信徒", maxHP: hp)
    }
}
```

**验收标准**：
- [ ] `swift build` 成功
- [ ] 游戏可正常运行

---

### P1.2：创建 EnemyKind 枚举 ⭐ 15分钟

**状态**：✅ 已完成

**创建文件**：
- `Sources/GameCore/Enemies/EnemyKind.swift`

**代码内容**：

```swift
/// 敌人种类
/// 每种敌人有唯一标识符和显示名称
public enum EnemyKind: String, CaseIterable, Sendable {
    case jawWorm = "jaw_worm"
    case cultist = "cultist"
    case louseGreen = "louse_green"
    case louseRed = "louse_red"
    case slimeMediumAcid = "slime_medium_acid"
    
    /// 显示名称
    public var displayName: String {
        switch self {
        case .jawWorm: return "下颚虫"
        case .cultist: return "信徒"
        case .louseGreen: return "绿虱子"
        case .louseRed: return "红虱子"
        case .slimeMediumAcid: return "酸液史莱姆"
        }
    }
}
```

**验收标准**：
- [ ] 新文件编译通过
- [ ] 可从其他文件引用

---

### P1.3：创建 EnemyData 静态数据 ⭐ 15分钟

**状态**：✅ 已完成

**创建文件**：
- `Sources/GameCore/Enemies/EnemyData.swift`

**代码内容**：

```swift
/// 敌人静态数据
/// 包含 HP 范围、基础攻击力等属性
public struct EnemyData: Sendable {
    public let kind: EnemyKind
    public let minHP: Int
    public let maxHP: Int
    public let baseAttackDamage: Int
    
    /// 获取敌人数据
    public static func get(_ kind: EnemyKind) -> EnemyData {
        switch kind {
        case .jawWorm:
            return EnemyData(kind: kind, minHP: 40, maxHP: 44, baseAttackDamage: 11)
        case .cultist:
            return EnemyData(kind: kind, minHP: 48, maxHP: 54, baseAttackDamage: 6)
        case .louseGreen:
            return EnemyData(kind: kind, minHP: 11, maxHP: 17, baseAttackDamage: 6)
        case .louseRed:
            return EnemyData(kind: kind, minHP: 10, maxHP: 15, baseAttackDamage: 6)
        case .slimeMediumAcid:
            return EnemyData(kind: kind, minHP: 28, maxHP: 32, baseAttackDamage: 10)
        }
    }
    
    /// 根据 RNG 生成实际 HP
    public func generateHP(rng: inout SeededRNG) -> Int {
        let range = maxHP - minHP + 1
        return minHP + rng.nextInt(upperBound: range)
    }
}
```

**验收标准**：
- [ ] 编译通过
- [ ] 可用于创建敌人

---

### P1.4：创建 EnemyIntent 意图系统 ⭐⭐ 30分钟

**状态**：✅ 已完成

**创建文件**：
- `Sources/GameCore/Enemies/EnemyIntent.swift`

**代码内容**：

```swift
/// 敌人意图类型
/// 描述敌人下一回合将执行的行动
public enum EnemyIntent: Sendable, Equatable {
    /// 纯攻击
    case attack(damage: Int)
    
    /// 攻击 + 施加 Debuff
    case attackDebuff(damage: Int, debuff: String, stacks: Int)
    
    /// 纯防御
    case defend(block: Int)
    
    /// 增益（给自己加 Buff）
    case buff(name: String, stacks: Int)
    
    /// 未知意图
    case unknown
    
    // MARK: - UI 显示
    
    /// 显示图标
    public var displayIcon: String {
        switch self {
        case .attack: return "⚔️"
        case .attackDebuff: return "⚔️💀"
        case .defend: return "🛡️"
        case .buff: return "💪"
        case .unknown: return "❓"
        }
    }
    
    /// 显示文本
    public var displayText: String {
        switch self {
        case .attack(let damage):
            return "攻击 \(damage)"
        case .attackDebuff(let damage, let debuff, let stacks):
            return "攻击 \(damage) + \(debuff) \(stacks)"
        case .defend(let block):
            return "防御 \(block)"
        case .buff(let name, let stacks):
            return "\(name) +\(stacks)"
        case .unknown:
            return "???"
        }
    }
}
```

**修改文件**：
- `Sources/GameCore/Entity/Entity.swift`

**添加属性**：
```swift
/// 当前意图（仅敌人使用）
public var intent: EnemyIntent = .unknown
```

**修改文件**：
- `Sources/GameCLI/Screens/BattleScreen.swift`

**更新意图显示**：
```swift
// 替换硬编码的意图显示
let intentText = "\(enemy.intent.displayIcon) 意图: \(enemy.intent.displayText)"
lines.append("     \(Terminal.yellow)\(intentText)\(Terminal.reset)")
```

**验收标准**：
- [ ] 编译通过
- [ ] 战斗界面显示敌人意图
- [ ] 意图根据 Entity.intent 动态显示

---

### P1.5：创建 EnemyAI 决策系统 ⭐⭐⭐ 1小时

**状态**：✅ 已完成

**创建文件**：
- `Sources/GameCore/Enemies/EnemyAI.swift`

**代码内容**：

```swift
/// 敌人 AI 决策协议
public protocol EnemyAI: Sendable {
    /// 决定下一个行动意图
    func decideIntent(
        enemy: Entity,
        player: Entity,
        turn: Int,
        rng: inout SeededRNG
    ) -> EnemyIntent
}

/// AI 工厂
public enum EnemyAIFactory {
    public static func create(for kind: EnemyKind) -> any EnemyAI {
        switch kind {
        case .jawWorm:
            return JawWormAI()
        case .cultist:
            return CultistAI()
        case .louseGreen, .louseRed:
            return LouseAI()
        case .slimeMediumAcid:
            return SlimeAI()
        }
    }
}
```

**创建文件**：
- `Sources/GameCore/Enemies/EnemyBehaviors.swift`

**代码内容**：

```swift
/// 下颚虫 AI
/// 行为模式：咬（11伤害）、嚎叫（+3力量）、猛扑（7伤害+5格挡）
public struct JawWormAI: EnemyAI, Sendable {
    public init() {}
    
    public func decideIntent(
        enemy: Entity,
        player: Entity,
        turn: Int,
        rng: inout SeededRNG
    ) -> EnemyIntent {
        let roll = rng.nextInt(upperBound: 100)
        
        if turn == 1 {
            // 第一回合 75% 咬
            return roll < 75 ? .attack(damage: 11) : .buff(name: "力量", stacks: 3)
        }
        
        // 后续回合
        if roll < 45 {
            return .attack(damage: 11)
        } else if roll < 75 {
            return .buff(name: "力量", stacks: 3)
        } else {
            return .attackDebuff(damage: 7, debuff: "格挡", stacks: 5)
        }
    }
}

/// 信徒 AI
/// 行为模式：第一回合念咒（+3力量），后续攻击
public struct CultistAI: EnemyAI, Sendable {
    public init() {}
    
    public func decideIntent(
        enemy: Entity,
        player: Entity,
        turn: Int,
        rng: inout SeededRNG
    ) -> EnemyIntent {
        if turn == 1 {
            return .buff(name: "力量", stacks: 3)
        }
        return .attack(damage: 6 + enemy.strength)
    }
}

/// 虱子 AI
/// 行为模式：攻击为主，偶尔卷曲（+3力量）
public struct LouseAI: EnemyAI, Sendable {
    public init() {}
    
    public func decideIntent(
        enemy: Entity,
        player: Entity,
        turn: Int,
        rng: inout SeededRNG
    ) -> EnemyIntent {
        let roll = rng.nextInt(upperBound: 100)
        if roll < 75 {
            return .attack(damage: 6 + enemy.strength)
        } else {
            return .buff(name: "力量", stacks: 3)
        }
    }
}

/// 史莱姆 AI
/// 行为模式：攻击 + 涂抹（施加虚弱）
public struct SlimeAI: EnemyAI, Sendable {
    public init() {}
    
    public func decideIntent(
        enemy: Entity,
        player: Entity,
        turn: Int,
        rng: inout SeededRNG
    ) -> EnemyIntent {
        let roll = rng.nextInt(upperBound: 100)
        if roll < 70 {
            return .attack(damage: 10)
        } else {
            return .attackDebuff(damage: 7, debuff: "虚弱", stacks: 1)
        }
    }
}
```

**修改文件**：
- `Sources/GameCore/Battle/BattleEngine.swift`

**关键改动**：
1. 添加 `enemyKind: EnemyKind` 属性
2. 添加 `enemyAI: any EnemyAI` 属性
3. 在 `startNewTurn()` 中调用 AI 决定意图
4. 在 `executeEnemyTurn()` 中根据意图执行

**验收标准**：
- [ ] 编译通过
- [ ] 敌人展示动态意图
- [ ] 敌人根据意图执行不同行动
- [ ] 测试脚本通过

---

### P1.6：添加更多敌人并测试平衡 ⭐⭐ 1小时

**状态**：✅ 已完成

**创建文件**：
- `Sources/GameCore/Enemies/EnemyPool.swift`

**代码内容**：

```swift
/// 第一章敌人池
public enum Act1EnemyPool {
    /// 弱敌人（前几场战斗）
    public static let weak: [EnemyKind] = [
        .jawWorm, .cultist, .louseGreen, .louseRed
    ]
    
    /// 中等敌人（中期战斗）
    public static let medium: [EnemyKind] = [
        .slimeMediumAcid
    ]
    
    /// 随机选择弱敌人
    public static func randomWeak(rng: inout SeededRNG) -> EnemyKind {
        let index = rng.nextInt(upperBound: weak.count)
        return weak[index]
    }
}
```

**验收标准**：
- [ ] 编译通过
- [ ] 游戏随机出现不同敌人
- [ ] 每种敌人有独特行为
- [ ] 测试脚本通过

---

## 📁 文件变更汇总

### 新建文件

| 文件路径 | 说明 |
|---------|------|
| `Sources/GameCore/Enemies/EnemyKind.swift` | 敌人种类枚举 |
| `Sources/GameCore/Enemies/EnemyData.swift` | 敌人静态数据 |
| `Sources/GameCore/Enemies/EnemyIntent.swift` | 敌人意图类型 |
| `Sources/GameCore/Enemies/EnemyAI.swift` | AI 决策协议 |
| `Sources/GameCore/Enemies/EnemyBehaviors.swift` | 具体敌人行为 |
| `Sources/GameCore/Enemies/EnemyPool.swift` | 敌人池/遭遇表 |

### 修改文件

| 文件路径 | 变更内容 |
|---------|---------|
| `Sources/GameCore/Entity/Entity.swift` | 添加 intent 属性 |
| `Sources/GameCore/Battle/BattleEngine.swift` | 集成 AI 系统 |
| `Sources/GameCLI/Screens/BattleScreen.swift` | 动态意图显示 |

---

## 🎯 验收标准

- [x] 游戏随机出现至少 5 种不同敌人（信徒、下颚虫、绿虱子、红虱子、酸液史莱姆）
- [x] 每种敌人有独特的 AI 行为
- [x] 敌人意图正确显示在界面上
- [x] 敌人根据状态智能选择行动
- [x] `swift build` 编译成功
- [x] 测试脚本通过（4/4 套件全部通过，耗时 ~2秒）

---

## 📝 修订历史

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-01-02 | v1.0 | Plan A 初稿 |
| 2026-01-02 | v1.1 | ✅ 全部完成，标记为已完成 |

