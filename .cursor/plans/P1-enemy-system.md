# P1：敌人系统 + AI 详细开发计划

> 创建时间：2026-01-01
> 状态：计划中
> 预计总时间：~3 小时

---

## 📋 目标

创建完整的敌人系统，包括：
- 多种敌人类型
- 敌人 AI 决策系统
- 敌人意图显示

---

## 📁 需要创建的文件

```
Sources/GameCore/Enemies/
├── EnemyKind.swift        # 敌人种类枚举
├── EnemyData.swift        # 敌人静态数据
├── EnemyIntent.swift      # 敌人意图类型
├── EnemyAI.swift          # AI 决策协议
└── EnemyBehaviors.swift   # 具体敌人行为实现
```

---

## 🔄 Step by Step

### P1.1：添加第二个敌人（硬编码）⭐ 10分钟

**目标**：让游戏能随机出现不同敌人

**修改文件**：
- `Sources/GameCore/Entity/Entity.swift`

**具体改动**：
```swift
// 新增敌人创建函数
public func createEnemy(type: String) -> Entity {
    switch type {
    case "cultist":
        return Entity(id: "cultist", name: "信徒", maxHP: 50)
    default:
        return Entity(id: "jaw_worm", name: "下颚虫", maxHP: 42)
    }
}
```

**修改文件**：
- `Sources/GameCore/Battle/BattleEngine.swift`

**具体改动**：
```swift
// init 中随机选择敌人
let enemyTypes = ["jaw_worm", "cultist"]
let selectedType = enemyTypes[Int(rng.next() % UInt64(enemyTypes.count))]
let enemy = createEnemy(type: selectedType)
```

**验收**：运行游戏，有时遇到下颚虫，有时遇到信徒

---

### P1.2：创建 EnemyKind 枚举 ⭐ 15分钟

**目标**：用类型安全的枚举替代字符串

**创建文件**：
- `Sources/GameCore/Enemies/EnemyKind.swift`

```swift
/// 敌人种类
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

**验收**：编译通过

---

### P1.3：创建 EnemyData 静态数据 ⭐ 15分钟

**目标**：将敌人属性集中管理

**创建文件**：
- `Sources/GameCore/Enemies/EnemyData.swift`

```swift
/// 敌人静态数据
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
        return minHP + Int(rng.next() % UInt64(maxHP - minHP + 1))
    }
}
```

**验收**：编译通过

---

### P1.4：创建 EnemyIntent 意图系统 ⭐⭐ 30分钟

**目标**：敌人每回合展示不同意图

**创建文件**：
- `Sources/GameCore/Enemies/EnemyIntent.swift`

```swift
/// 敌人意图类型
public enum EnemyIntent: Sendable, Equatable {
    case attack(damage: Int)
    case attackDebuff(damage: Int, debuff: String, stacks: Int)
    case defend(block: Int)
    case buff(buff: String, stacks: Int)
    case unknown
    
    /// 用于 UI 显示
    public var displayIcon: String {
        switch self {
        case .attack: return "⚔️"
        case .attackDebuff: return "⚔️💀"
        case .defend: return "🛡️"
        case .buff: return "💪"
        case .unknown: return "❓"
        }
    }
    
    /// 用于 UI 显示的描述
    public var displayText: String {
        switch self {
        case .attack(let damage):
            return "攻击 \(damage) 伤害"
        case .attackDebuff(let damage, let debuff, let stacks):
            return "攻击 \(damage) + \(debuff) \(stacks)"
        case .defend(let block):
            return "防御 \(block)"
        case .buff(let buff, let stacks):
            return "\(buff) +\(stacks)"
        case .unknown:
            return "???"
        }
    }
}
```

**修改文件**：
- `Sources/GameCore/Entity/Entity.swift`

**新增属性**：
```swift
public struct Entity: Sendable {
    // ... 现有属性 ...
    
    /// 当前意图（仅敌人使用）
    public var intent: EnemyIntent = .unknown
}
```

**修改文件**：
- `Sources/GameCLI/Screens/BattleScreen.swift`

**修改意图显示**：
```swift
// 替换硬编码的意图显示
let intentText = "\(enemy.intent.displayIcon) 意图: \(enemy.intent.displayText)"
lines.append("     \(Terminal.yellow)\(intentText)\(Terminal.reset)")
```

**验收**：战斗界面正确显示敌人意图

---

### P1.5：创建 EnemyAI 决策系统 ⭐⭐⭐ 1小时

**目标**：敌人根据状态智能选择行动

**创建文件**：
- `Sources/GameCore/Enemies/EnemyAI.swift`

```swift
/// 敌人 AI 决策协议
public protocol EnemyAI: Sendable {
    /// 决定下一个行动意图
    func decideIntent(
        enemy: Entity,
        player: Entity,
        turn: Int,
        lastIntent: EnemyIntent?,
        rng: inout SeededRNG
    ) -> EnemyIntent
    
    /// 执行当前意图
    func executeIntent(
        intent: EnemyIntent,
        enemy: inout Entity,
        player: inout Entity
    ) -> [BattleEvent]
}
```

**创建文件**：
- `Sources/GameCore/Enemies/EnemyBehaviors.swift`

```swift
/// 下颚虫 AI
public struct JawWormAI: EnemyAI {
    public init() {}
    
    public func decideIntent(
        enemy: Entity,
        player: Entity,
        turn: Int,
        lastIntent: EnemyIntent?,
        rng: inout SeededRNG
    ) -> EnemyIntent {
        // 下颚虫有三种行动：咬（伤害）、嚎叫（+力量）、猛扑（伤害+格挡）
        let roll = Int(rng.next() % 100)
        
        if turn == 1 {
            // 第一回合 50% 咬，50% 嚎叫
            return roll < 50 ? .attack(damage: 11) : .buff(buff: "力量", stacks: 3)
        }
        
        // 根据上次行动决定
        switch lastIntent {
        case .attack:
            // 上次攻击 → 30% 再攻，30% 嚎叫，40% 猛扑
            if roll < 30 { return .attack(damage: 11) }
            if roll < 60 { return .buff(buff: "力量", stacks: 3) }
            return .attackDebuff(damage: 7, debuff: "格挡", stacks: 5)
            
        case .buff:
            // 上次增益 → 70% 攻击，30% 猛扑
            if roll < 70 { return .attack(damage: 11) }
            return .attackDebuff(damage: 7, debuff: "格挡", stacks: 5)
            
        default:
            return .attack(damage: 11)
        }
    }
    
    public func executeIntent(
        intent: EnemyIntent,
        enemy: inout Entity,
        player: inout Entity
    ) -> [BattleEvent] {
        // 具体执行逻辑
        var events: [BattleEvent] = []
        // ... 实现 ...
        return events
    }
}

/// 信徒 AI
public struct CultistAI: EnemyAI {
    // 信徒的特点：第一回合念咒（增加攻击力），后续持续攻击
    // ...
}

/// 虱子 AI
public struct LouseAI: EnemyAI {
    // 虱子的特点：攻击时可能增加力量
    // ...
}
```

**修改文件**：
- `Sources/GameCore/Battle/BattleEngine.swift`

**集成 AI 系统**：
```swift
// 在 BattleEngine 中添加 AI 引用
private let enemyAI: any EnemyAI

// 在回合开始时决定意图
func startNewTurn() {
    // ...
    state.enemy.intent = enemyAI.decideIntent(
        enemy: state.enemy,
        player: state.player,
        turn: state.turn,
        lastIntent: lastEnemyIntent,
        rng: &rng
    )
}
```

**验收**：敌人展示不同意图，并且行为有智能变化

---

### P1.6：添加更多敌人并测试平衡 ⭐⭐ 1小时

**目标**：丰富敌人池，测试游戏平衡

**添加敌人**：

1. **绿虱子 (Louse Green)**
   - HP: 11-17
   - 行为：攻击 5-7，有时卷曲（+3 力量）

2. **红虱子 (Louse Red)**
   - HP: 10-15
   - 行为：攻击 5-7，有时卷曲（+3 力量）

3. **酸液史莱姆 (Acid Slime Medium)**
   - HP: 28-32
   - 行为：攻击、涂抹（施加虚弱）

4. **尖刺史莱姆 (Spike Slime Medium)**
   - HP: 28-32
   - 行为：攻击、舔舐（施加易伤）

**创建敌人池**：
```swift
/// 第一章敌人池
public enum Act1EnemyPool {
    /// 弱敌人（前几场战斗）
    public static let weak: [EnemyKind] = [
        .jawWorm, .cultist, .louseGreen, .louseRed
    ]
    
    /// 中等敌人（中期战斗）
    public static let medium: [EnemyKind] = [
        .slimeMediumAcid, .slimeMediumSpike
    ]
    
    /// 随机选择弱敌人
    public static func randomWeak(rng: inout SeededRNG) -> EnemyKind {
        let index = Int(rng.next() % UInt64(weak.count))
        return weak[index]
    }
}
```

**验收**：游戏有 5-6 种不同敌人，每种有独特行为

---

## 🎯 验收标准

- [ ] 游戏随机出现至少 5 种不同敌人
- [ ] 每种敌人有独特的 AI 行为
- [ ] 敌人意图正确显示在界面上
- [ ] 敌人根据状态智能选择行动
- [ ] `swift build` 编译成功
- [ ] 测试脚本通过

---

## 📝 注意事项

1. **保持可运行**：每一步完成后游戏都应该可以正常运行
2. **渐进式开发**：先硬编码，再抽象
3. **测试驱动**：每步完成后实际玩一局验证
4. **数值参考**：可参考杀戮尖塔 Wiki 的敌人数据

---

## 📚 参考资源

- [Slay the Spire Wiki - Enemies](https://slay-the-spire.fandom.com/wiki/Category:Enemies)

---

## 📝 修订历史

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-01-01 | v1.0 | 初稿 |

