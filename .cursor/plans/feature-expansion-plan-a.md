# Salu 功能扩展开发计划 - Plan A

> 创建时间：2026-01-01
> 版本：v1.0

---

## 📋 计划概述

本计划按优先级分阶段实现新功能，每个阶段完成后需验证构建成功。

### 优先级总览

| 优先级 | 功能 | 复杂度 | 预计改动文件 |
|--------|------|--------|--------------|
| P0 | 状态效果系统（基础设施） | ⭐⭐⭐ | 4 个 |
| P1 | 新卡牌（Pommel Strike / Shrug It Off） | ⭐⭐ | 4 个 |
| P2 | 新卡牌 Bash + 易伤效果 | ⭐⭐ | 2 个 |
| P3 | 虚弱/力量状态效果 | ⭐⭐ | 3 个 |

---

## P0：状态效果系统（基础设施）🏗️

**目标**：为状态效果（Buff/Debuff）建立基础架构

### 涉及文件

| 文件 | 改动类型 | 说明 |
|------|----------|------|
| `Sources/GameCore/Models.swift` | 修改 | 添加 `Entity` 状态字段 |
| `Sources/GameCore/Events.swift` | 修改 | 添加状态效果相关事件 |
| `Sources/GameCore/BattleEngine.swift` | 修改 | 伤害计算应用状态修正、回合结束递减 |
| `Sources/GameCLI/ScreenRenderer.swift` | 修改 | 显示状态效果图标 |
| `Sources/GameCLI/EventFormatter.swift` | 修改 | 格式化状态效果事件 |

### 详细步骤

#### Step 1: 修改 `Models.swift` - 添加状态字段

在 `Entity` 结构体中添加状态效果字段：

```swift
public struct Entity: Sendable {
    // ... 现有字段 ...
    
    // 状态效果（回合数）
    public var vulnerable: Int = 0   // 易伤：受到伤害 +50%
    public var weak: Int = 0         // 虚弱：造成伤害 -25%
    public var strength: Int = 0     // 力量：攻击伤害 +N
    
    // 新增方法
    public mutating func tickStatusEffects() {
        vulnerable = max(0, vulnerable - 1)
        weak = max(0, weak - 1)
        // strength 不递减（永久效果）
    }
    
    public var hasAnyStatus: Bool {
        vulnerable > 0 || weak > 0 || strength != 0
    }
}
```

**注意**：需要更新 `Entity.init()` 方法。

#### Step 2: 修改 `Events.swift` - 添加状态事件

```swift
public enum BattleEvent: Sendable, Equatable {
    // ... 现有 case ...
    
    /// 获得状态效果
    case statusApplied(target: String, effect: String, stacks: Int)
    
    /// 状态效果过期
    case statusExpired(target: String, effect: String)
    
    /// 状态效果递减
    case statusTicked(target: String, effect: String, remaining: Int)
}
```

同时更新 `description` 扩展。

#### Step 3: 修改 `BattleEngine.swift` - 伤害计算

1. **修改伤害计算**：应用易伤/虚弱/力量修正

```swift
private func calculateDamage(baseDamage: Int, attacker: Entity, defender: Entity) -> Int {
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
```

2. **回合结束时递减状态**：在 `startNewTurn()` 中调用

#### Step 4: 修改 UI 显示

在 `ScreenRenderer.buildPlayerArea()` 和 `buildEnemyArea()` 中添加状态图标显示。

### 验证点

- [ ] `swift build` 成功
- [ ] 运行游戏，状态字段初始化正确
- [ ] 无编译警告

---

## P1：新卡牌（Pommel Strike / Shrug It Off）⚔️🛡️

**目标**：添加两张不依赖状态效果的新卡牌

### 卡牌规格

| 卡牌 | 费用 | 效果 |
|------|------|------|
| Pommel Strike | 1 能量 | 造成 9 伤害，抽 1 张牌 |
| Shrug It Off | 1 能量 | 获得 8 格挡，抽 1 张牌 |

### 涉及文件

| 文件 | 改动类型 | 说明 |
|------|----------|------|
| `Sources/GameCore/Models.swift` | 修改 | 添加 `CardKind` 枚举值 |
| `Sources/GameCore/BattleEngine.swift` | 修改 | 实现卡牌效果 |
| `Sources/GameCore/History.swift` | 修改 | 统计新卡牌使用 |
| `Sources/GameCLI/ScreenRenderer.swift` | 修改 | 显示新卡牌效果描述 |

### 详细步骤

#### Step 1: 修改 `Models.swift`

1. 添加新的 `CardKind`：

```swift
public enum CardKind: String, Sendable {
    case strike         // 攻击牌：1能量，造成6伤害
    case defend         // 防御牌：1能量，获得5格挡
    case pommelStrike   // 柄击：1能量，造成9伤害，抽1张牌
    case shrugItOff     // 耸肩：1能量，获得8格挡，抽1张牌
}
```

2. 更新 `Card` 的计算属性：

```swift
public var cost: Int {
    switch kind {
    case .strike, .defend, .pommelStrike, .shrugItOff: return 1
    }
}

public var damage: Int {
    switch kind {
    case .strike: return 6
    case .pommelStrike: return 9
    case .defend, .shrugItOff: return 0
    }
}

public var block: Int {
    switch kind {
    case .defend: return 5
    case .shrugItOff: return 8
    case .strike, .pommelStrike: return 0
    }
}

/// 抽牌数
public var drawCount: Int {
    switch kind {
    case .pommelStrike, .shrugItOff: return 1
    default: return 0
    }
}

public var displayName: String {
    switch kind {
    case .strike: return "Strike"
    case .defend: return "Defend"
    case .pommelStrike: return "Pommel Strike"
    case .shrugItOff: return "Shrug It Off"
    }
}
```

3. 更新 `createStarterDeck()`：

```swift
public func createStarterDeck() -> [Card] {
    var cards: [Card] = []
    
    // 4 张 Strike（原来 5 张）
    for i in 1...4 {
        cards.append(Card(id: "strike_\(i)", kind: .strike))
    }
    
    // 4 张 Defend（原来 5 张）
    for i in 1...4 {
        cards.append(Card(id: "defend_\(i)", kind: .defend))
    }
    
    // 1 张 Pommel Strike
    cards.append(Card(id: "pommelStrike_1", kind: .pommelStrike))
    
    // 1 张 Shrug It Off
    cards.append(Card(id: "shrugItOff_1", kind: .shrugItOff))
    
    return cards  // 总计 10 张
}
```

#### Step 2: 修改 `BattleEngine.swift`

更新 `executeCardEffect()`：

```swift
private func executeCardEffect(_ card: Card) {
    switch card.kind {
    case .strike:
        let finalDamage = calculateDamage(baseDamage: card.damage, attacker: state.player, defender: state.enemy)
        let (dealt, blocked) = state.enemy.takeDamage(finalDamage)
        emit(.damageDealt(source: state.player.name, target: state.enemy.name, amount: dealt, blocked: blocked))
        
    case .pommelStrike:
        // 造成伤害
        let finalDamage = calculateDamage(baseDamage: card.damage, attacker: state.player, defender: state.enemy)
        let (dealt, blocked) = state.enemy.takeDamage(finalDamage)
        emit(.damageDealt(source: state.player.name, target: state.enemy.name, amount: dealt, blocked: blocked))
        // 抽牌
        drawCards(card.drawCount)
        
    case .defend:
        state.player.gainBlock(card.block)
        emit(.blockGained(target: state.player.name, amount: card.block))
        
    case .shrugItOff:
        // 获得格挡
        state.player.gainBlock(card.block)
        emit(.blockGained(target: state.player.name, amount: card.block))
        // 抽牌
        drawCards(card.drawCount)
    }
}
```

#### Step 3: 修改 `ScreenRenderer.swift`

更新 `buildHandArea()` 中的效果描述：

```swift
let effect: String
let effectIcon: String
switch card.kind {
case .strike:
    effect = "造成 \(card.damage) 伤害"
    effectIcon = "⚔️"
case .pommelStrike:
    effect = "造成 \(card.damage) 伤害, 抽 1 张"
    effectIcon = "⚔️"
case .defend:
    effect = "获得 \(card.block) 格挡"
    effectIcon = "🛡️"
case .shrugItOff:
    effect = "获得 \(card.block) 格挡, 抽 1 张"
    effectIcon = "🛡️"
}
```

#### Step 4: 修改 `History.swift`

更新 `BattleRecordBuilder` 以统计新卡牌：

```swift
case .played(_, let cardName, _):
    switch cardName {
    case "Strike": strikesPlayed += 1
    case "Defend": defendsPlayed += 1
    case "Pommel Strike": strikesPlayed += 1  // 算作攻击牌
    case "Shrug It Off": defendsPlayed += 1   // 算作防御牌
    default: break
    }
```

### 验证点

- [ ] `swift build` 成功
- [ ] 运行游戏，新卡牌显示正确
- [ ] 使用 Pommel Strike 后抽牌
- [ ] 使用 Shrug It Off 后抽牌
- [ ] 战绩统计正确

---

## P2：新卡牌 Bash + 易伤效果 💪

**目标**：添加 Bash 卡牌，可给敌人施加易伤

### 卡牌规格

| 卡牌 | 费用 | 效果 |
|------|------|------|
| Bash | 2 能量 | 造成 8 伤害，给予易伤 2 回合 |

### 涉及文件

| 文件 | 改动类型 | 说明 |
|------|----------|------|
| `Sources/GameCore/Models.swift` | 修改 | 添加 `CardKind.bash` |
| `Sources/GameCore/BattleEngine.swift` | 修改 | 实现 Bash 效果 |

### 详细步骤

#### Step 1: 修改 `Models.swift`

```swift
public enum CardKind: String, Sendable {
    // ... 现有 ...
    case bash  // 重击：2能量，造成8伤害，给予易伤2
}

// 更新 Card 属性
public var cost: Int {
    switch kind {
    // ...
    case .bash: return 2
    }
}

public var damage: Int {
    switch kind {
    // ...
    case .bash: return 8
    }
}

/// 施加易伤回合数
public var vulnerableApply: Int {
    switch kind {
    case .bash: return 2
    default: return 0
    }
}

public var displayName: String {
    switch kind {
    // ...
    case .bash: return "Bash"
    }
}
```

更新初始牌组（可选，替换一张 Strike）。

#### Step 2: 修改 `BattleEngine.swift`

```swift
case .bash:
    // 造成伤害
    let finalDamage = calculateDamage(baseDamage: card.damage, attacker: state.player, defender: state.enemy)
    let (dealt, blocked) = state.enemy.takeDamage(finalDamage)
    emit(.damageDealt(source: state.player.name, target: state.enemy.name, amount: dealt, blocked: blocked))
    
    // 施加易伤
    if card.vulnerableApply > 0 {
        state.enemy.vulnerable += card.vulnerableApply
        emit(.statusApplied(target: state.enemy.name, effect: "易伤", stacks: card.vulnerableApply))
    }
```

#### Step 3: 更新 UI 显示

在 `ScreenRenderer` 中更新：

```swift
case .bash:
    effect = "造成 \(card.damage) 伤害, 易伤 2"
    effectIcon = "💥"
```

### 验证点

- [ ] `swift build` 成功
- [ ] Bash 卡牌正确消耗 2 能量
- [ ] 使用 Bash 后敌人获得易伤状态
- [ ] 易伤状态使敌人受到 +50% 伤害
- [ ] 易伤状态每回合递减

---

## P3：虚弱/力量状态效果 💪😵

**目标**：完善状态效果系统（可作为后续敌人 AI 或新卡牌的基础）

### 涉及内容

1. **虚弱（Weak）**：已在 P0 中添加字段
   - 效果：造成伤害 -25%
   - 可通过未来卡牌/敌人施加

2. **力量（Strength）**：已在 P0 中添加字段
   - 效果：攻击伤害 +N
   - 可通过未来卡牌/遗物获得

### 涉及文件

| 文件 | 改动类型 | 说明 |
|------|----------|------|
| `Sources/GameCore/BattleEngine.swift` | 验证 | 确认伤害计算正确 |
| `Sources/GameCLI/ScreenRenderer.swift` | 修改 | 显示力量/虚弱状态 |
| `Sources/GameCLI/EventFormatter.swift` | 修改 | 格式化相关事件 |

### 验证点

- [ ] 虚弱使攻击伤害 -25%
- [ ] 力量使攻击伤害 +N
- [ ] 状态图标正确显示
- [ ] 战斗中状态递减正常

---

## 🔧 技术注意事项

### 1. 保持向后兼容

- `BattleRecord` 新增字段需要提供默认值
- 考虑旧的战绩记录可能没有新卡牌统计

### 2. 测试建议

每个阶段完成后：

```bash
# 构建验证
swift build

# 运行游戏测试
swift run GameCLI --seed 1
```

### 3. 文档同步

完成所有改动后，更新：
- `CLAUDE.mdc`：卡牌列表、数值设定
- `README.md`：新功能说明

---

## ✅ 进度检查清单

- [ ] **P0 完成**：状态效果系统基础设施
  - [ ] Models.swift 修改完成
  - [ ] Events.swift 修改完成
  - [ ] BattleEngine.swift 修改完成
  - [ ] UI 显示更新完成
  - [ ] `swift build` 验证通过

- [ ] **P1 完成**：Pommel Strike / Shrug It Off
  - [ ] 卡牌定义完成
  - [ ] 效果实现完成
  - [ ] UI 显示完成
  - [ ] `swift build` 验证通过

- [ ] **P2 完成**：Bash + 易伤
  - [ ] 卡牌定义完成
  - [ ] 效果实现完成
  - [ ] 易伤伤害计算正确
  - [ ] `swift build` 验证通过

- [ ] **P3 完成**：虚弱/力量
  - [ ] 伤害计算验证
  - [ ] UI 显示完成
  - [ ] `swift build` 验证通过

---

## 📝 备注

- 本计划假设按顺序执行，P1 依赖 P0 的伤害计算函数
- 如遇问题可调整顺序，先实现 P1 中不需要伤害修正的部分
- 每个 P 完成后建议 commit 一次，便于回滚

