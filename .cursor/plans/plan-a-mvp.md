# Salu MVP 开发计划 - Plan A

## ✅ MVP 已完成！

**完成时间**：2026-01-01

---

## 项目现状（完成后）

| 组件 | 状态 | 说明 |
|------|------|------|
| Package.swift | ✅ 已完成 | 包含 GameCore 库和 GameCLI 可执行目标 |
| GameCore/ | ✅ 已完成 | 5 个文件：Models, RNG, Events, Actions, BattleEngine |
| GameCLI/ | ✅ 已完成 | 完整的 CLI 交互实现 |

---

## 优先级划分

### ✅ P1 - 基础数据模型与 Package 配置
**目标**：建立项目骨架，能够编译通过

- [x] 1.1 更新 `Package.swift`，添加 GameCore 库目标
- [x] 1.2 创建 `GameCore/Models.swift`：定义核心数据类型
  - `CardKind` 枚举（strike / defend）
  - `Card` 结构体（id, kind, cost, damage, block）
  - `Entity` 结构体（玩家/敌人的 HP, Block）
  - `BattleState` 结构体（牌堆/手牌/弃牌堆/能量/回合数）
- [x] 1.3 创建 `GameCore/RNG.swift`：可复现的随机数生成器
  - 支持固定 seed
  - 提供 shuffle 方法

**验收**：✅ `swift build` 编译成功

---

### ✅ P2 - 事件系统
**目标**：定义战斗事件，为日志和测试提供基础

- [x] 2.1 创建 `GameCore/Events.swift`：定义 `BattleEvent` 枚举
  - `battleStarted`
  - `turnStarted(turn: Int)`
  - `energyReset(amount: Int)`
  - `blockCleared(target: String, amount: Int)`
  - `drew(cardId: String, cardName: String)`
  - `shuffled(count: Int)`
  - `played(cardId: String, cardName: String, cost: Int)`
  - `damageDealt(source: String, target: String, amount: Int, blocked: Int)`
  - `blockGained(target: String, amount: Int)`
  - `handDiscarded(count: Int)`
  - `enemyIntent(enemyId: String, action: String, damage: Int)`
  - `enemyAction(enemyId: String, action: String)`
  - `turnEnded(turn: Int)`
  - `entityDied(entityId: String, name: String)`
  - `battleWon` / `battleLost`
  - `notEnoughEnergy(required: Int, available: Int)`
  - `invalidAction(reason: String)`

**验收**：✅ `swift build` 编译成功

---

### ✅ P3 - 战斗引擎核心
**目标**：实现战斗逻辑的核心计算

- [x] 3.1 创建 `GameCore/Actions.swift`：定义玩家动作
  - `PlayerAction` 枚举（playCard / endTurn）
- [x] 3.2 创建 `GameCore/BattleEngine.swift`：战斗引擎
  - 初始化战斗（创建初始牌组、洗牌）
  - 回合开始处理（重置能量、清除玩家格挡、抽牌）
  - 出牌处理（消耗能量、执行卡牌效果）
  - 伤害结算（先扣格挡再扣血）
  - 回合结束处理（弃手牌、敌人行动）
  - 判断胜负

**验收**：✅ `swift build` 编译成功

---

### ✅ P4 - CLI 交互实现
**目标**：实现命令行用户界面

- [x] 4.1 更新 `GameCLI/GameCLI.swift`：完整 CLI 实现
  - 解析命令行参数（--seed / --seed=N）
  - 打印战斗状态（HP/Block/能量/手牌/牌堆信息）
  - 读取用户输入（1-n 出牌 / 0 结束回合 / q 退出）
  - 调用 BattleEngine 处理动作
  - 打印事件日志（带 Emoji）
  - 游戏主循环

**验收**：✅ `swift build` 编译成功，可运行

---

### ✅ P5 - 集成测试与调试
**目标**：确保游戏可完整运行一局

- [x] 5.1 运行 `swift run GameCLI --seed 1` 进行测试 ✅ 第 5 回合胜利
- [x] 5.2 验证同一 seed + 同样输入 = 相同结果 ✅ 可复现
- [x] 5.3 验证抽牌堆耗尽时正确洗回弃牌堆 ✅ 第 3、5 回合触发
- [x] 5.4 验证伤害与格挡结算正确 ✅ 格挡优先消耗
- [x] 5.5 修复发现的任何 bug ✅ 无 bug

**验收**：✅ 能完整跑完一局（胜利）

---

## 文件结构（最终）

```
salu/
├── Package.swift
├── Docs/
│   └── CLAUDE.md
├── .cursor/plans/
│   └── plan-a-mvp.md
└── Sources/
    ├── GameCore/
    │   ├── Models.swift         # 168 行
    │   ├── RNG.swift            # 63 行
    │   ├── Events.swift         # 123 行
    │   ├── Actions.swift        # 10 行
    │   └── BattleEngine.swift   # 230 行
    └── GameCLI/
        └── GameCLI.swift        # 145 行
```

**总代码量**：约 740 行

---

## 运行方式

```bash
# 使用固定 seed 运行（可复现）
swift run GameCLI --seed 1

# 使用随机 seed 运行
swift run GameCLI
```

---

## 验收标准回顾

| 标准 | 结果 |
|------|------|
| `swift run GameCLI --seed 1` 能跑完一局 | ✅ 第 5 回合胜利 |
| 同一 seed + 同样输入 → 结果一致 | ✅ 第一回合始终抽到 Defend, Strike×4 |
| 抽牌堆耗尽时正确洗回 | ✅ 第 3、5 回合触发洗牌 |
| 伤害与格挡结算正确 | ✅ 7 伤害 - 5 格挡 = 2 实际伤害 |

---

## 下一步扩展建议（MVP 之后）

根据 CLAUDE.md 的建议，下一步可以：

1. **增加 3 张新牌**：
   - Bash：2 能量，造成 8 伤害，给予易伤 2
   - Pommel Strike：1 能量，造成 7 伤害，抽 1
   - Shrug It Off：1 能量，获得 8 格挡，抽 1

2. **增加 Debuff 系统**：
   - Vulnerable（易伤）：受伤 +50%
   - Weak（虚弱）：造成伤害 -25%

3. **增加多敌人支持**

4. **增加卡牌升级机制**
