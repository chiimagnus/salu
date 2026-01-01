# Slay the Spire（简易仿制）CLI 版 MVP 计划

## 项目初始化

项目名：**Salu**

```bash
# 项目路径
cd /Users/chii_magnus/Github_OpenSource/salu

# 运行
swift run GameCLI
```

写代码可以用 Xcode 打开 `Package.swift`，运行用终端。

---

## 目标（MVP 的定义）

在 macOS 和 Windows 上都能运行的 **纯 CLI 回合制卡牌战斗 Demo**。

<aside>
🎯

做到这三件事就算 MVP：

- 能开局并初始化牌组
- 能进行多回合战斗（抽牌 → 出牌 → 敌人行动）
- 能稳定复现一局（固定随机种子）
</aside>

---

## MVP 范围（只做这些）

### 战斗循环

- 1v1：玩家 vs 1 个敌人
- 回合流程：
    1. 回合开始：能量重置、玩家格挡清零
    2. 抽牌：每回合抽 5
    3. 玩家出牌：直到能量不足或选择结束回合
    4. 回合结束：弃掉手牌
    5. 敌人行动：根据意图执行一次

### 数值与规则

- 玩家属性：HP、Block、Energy
- 敌人属性：HP、Block
- 伤害结算：
    - 先扣 Block，再扣 HP
    - Block 不跨回合（每回合开始清零）

### 牌与牌组（最小集合）

- 初始牌组：10 张
    - Strike x5：1 能量，造成 6 伤害
    - Defend x5：1 能量，获得 5 格挡
- 牌区：drawPile / hand / discardPile
- 洗牌：drawPile 空时，把 discardPile 洗回 drawPile

### 敌人 AI（最简单）

- 固定意图：每回合攻击 7

---

## 非目标（MVP 里明确不做）

- 地图、路线、事件
- 多敌人、目标选择
- Buff/Debuff（虚弱/易伤/力量）
- 卡牌升级、遗物、商店、删牌
- 动画、音效、图形界面
- 存档

---

## 项目结构（更直观版：先用“两个文件夹”就行）

使用 Swift Package Manager，跨平台友好。

### 文件夹结构

```
Salu/
├── Package.swift
└── Sources/
    ├── GameCore/       ← 底层逻辑（纯 Swift）
    │   └── Models.swift
    └── GameCLI/        ← 前端 UI（命令行）
        └── main.swift
```

- `GameCore/`：只负责规则、状态机、计算。**禁止** `print()`、读键盘输入、任何 UI 框架
- `GameCLI/`：只负责打印状态、读 stdin、把输入转成 action 调用 GameCore

<aside>
✅

记住一个单向依赖：CLI → GameCore。

GameCore 绝对不要 import CLI。

</aside>

### GameCore 里建议有哪些文件

- `Models.swift`
    - `Entity`（玩家/敌人）
    - `Card` / `CardKind`
    - `BattleState`（牌堆/手牌/能量/回合）
- `Events.swift`
    - `BattleEvent`（turnStarted / drew / played / damageDealt …）
- `RNG.swift`
    - 可注入、可固定 seed 的随机数（用于洗牌/敌人意图）
- `BattleEngine.swift`
    - 核心入口：接收 `Action`，更新 `State`，产出 `Event`

### CLI 里建议有哪些文件

- `main.swift`
    - while 循环：打印 → 读输入 → 调用 GameCore → 打印事件

---

## 可测试性设计（MVP 必做）

### 1）可复现随机数

- 引擎必须支持传入 `seed`
- 洗牌、抽牌、敌人意图都使用同一个 RNG
- 运行参数例：`--seed 1234`

### 2）事件日志（用于断言）

定义事件（示例）：

- `turnStarted(turn:Int)`
- `drew(cardId:String)`
- `played(cardId:String)`
- `damageDealt(source:String, target:String, amount:Int)`
- `blockGained(target:String, amount:Int)`
- `turnEnded(turn:Int)`

测试不依赖打印文本，而是断言：

- 关键状态（HP、Block、牌堆数量）
- 关键事件序列（Event）

---

## CLI 交互（MVP 版）

每回合输出：

- 玩家/敌人 HP、Block、能量
- 手牌列表（带序号与费用）

输入：

- `1..n`：打出第 n 张牌
- `0`：结束回合
- `q`：退出

---

## 验收标准（你跑一次就知道过没过）

- `swift run GameCLI --seed 1` 能跑完一局（胜/负都行）
- 同一个 seed + 同样输入序列 → 结果完全一致
- 抽牌堆耗尽时能正确洗回
- 伤害与格挡结算正确

---

## MVP 之后的第 1 个扩展（建议）

- 增加 3 张牌（各 1 张就够）：
    - Bash：2 能量，造成 8，给予易伤 2
    - Pommel Strike：1 能量，造成 7，抽 1
    - Shrug It Off：1 能量，获得 8 格挡，抽 1
- 增加 1 个 debuff：Vulnerable（受伤 +50%）