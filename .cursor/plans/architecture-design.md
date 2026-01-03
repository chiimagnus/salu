# Salu 架构设计文档

> 创建时间：2026-01-01
> 状态：讨论中
>
> ⚠️ 注意：协议驱动重构的**实施主文档**已迁移到 `.cursor/plans/protocol-driven-design-plan.md`。
> 本文档建议只保留“宏观架构/愿景”，其中的路线图（P 编号）可能与实施计划不一致，请以实施计划为准。

---

## 📋 概述

本文档描述 Salu 从单场战斗游戏扩展为完整冒险游戏的架构设计。

---

## 🏗️ 当前架构

### 模块依赖关系

```
                 ┌─────────────────────────────────────────┐
                 │            GameCLI（表现层）              │
                 │  ┌─────────────────────────────────────┐ │
                 │  │ Screens/ │ Components/ │ Terminal  │ │
                 │  └─────────────────────────────────────┘ │
                 └────────────────────┬────────────────────┘
                                      │ 依赖
                 ┌────────────────────▼────────────────────┐
                 │            GameCore（逻辑层）             │
                 │  ┌─────────────────────────────────────┐ │
                 │  │ Battle/ │ Cards/ │ Entity/ │ ...   │ │
                 │  └─────────────────────────────────────┘ │
                 └─────────────────────────────────────────┘
```

### 当前文件结构

```
Sources/
├── GameCore/                       # 纯逻辑层
│   ├── Battle/                     # 战斗系统
│   │   ├── BattleEngine.swift      # 战斗引擎（核心逻辑）
│   │   ├── BattleState.swift       # 战斗状态
│   │   └── BattleStats.swift       # 战斗统计
│   ├── Cards/                      # 卡牌系统
│   │   ├── CardKind.swift          # 卡牌种类枚举
│   │   ├── Card.swift              # 卡牌模型
│   │   └── StarterDeck.swift       # 初始牌组配置
│   ├── Entity/                     # 实体系统
│   │   └── Entity.swift            # 实体模型（玩家/敌人）
│   ├── Actions.swift               # 玩家动作定义
│   ├── Events.swift                # 战斗事件定义
│   ├── History.swift               # 战绩数据模型
│   └── RNG.swift                   # 随机数生成器
│
└── GameCLI/                        # 表现层
    ├── Screens/                    # 界面系统
    │   ├── MainMenuScreen.swift
    │   ├── SettingsScreen.swift
    │   ├── HelpScreen.swift
    │   ├── BattleScreen.swift
    │   ├── ResultScreen.swift
    │   ├── HistoryScreen.swift
    │   └── StatisticsScreen.swift
    ├── Components/                 # UI 组件
    │   └── EventFormatter.swift
    ├── GameCLI.swift               # 主入口
    ├── Terminal.swift              # ANSI 控制码
    ├── Screens.swift               # 界面统一入口
    └── HistoryManager.swift        # 战绩持久化
```

### 当前限制

| 限制 | 说明 |
|------|------|
| 单场战斗 | 每次运行只有一场战斗 |
| 单一敌人 | 只有下颚虫一种敌人 |
| 无地图 | 没有冒险进度系统 |
| 无遗物 | 没有被动效果系统 |
| 无卡牌升级 | 卡牌效果固定 |

---

## 🎯 目标架构

### 杀戮尖塔游戏流程

```
┌─────────────────────────────────────────────────────────────┐
│                         游戏会话（Run）                       │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  角色  │  遗物  │  卡组  │  金币  │  生命值  │  楼层    │ │
│  └────────────────────────────────────────────────────────┘ │
└────────────────────────────────┬────────────────────────────┘
                                 │
┌────────────────────────────────▼────────────────────────────┐
│                         地图系统（Map）                       │
│  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐               │
│  │  ⚔️  │→│  ❓  │→│  🛒  │→│  ⚔️  │→│  👹  │               │
│  │战斗 │  │事件 │  │商店 │  │战斗 │  │Boss │               │
│  └─────┘  └─────┘  └─────┘  └─────┘  └─────┘               │
└────────────────────────────────┬────────────────────────────┘
                                 │
┌────────────────────────────────▼────────────────────────────┐
│                         房间系统（Room）                      │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐              │
│  │  战斗房间  │ │  事件房间  │ │  商店房间  │ ...          │
│  └────────────┘ └────────────┘ └────────────┘              │
└────────────────────────────────┬────────────────────────────┘
                                 │
┌────────────────────────────────▼────────────────────────────┐
│                       战斗引擎（现有）                        │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  BattleEngine  │  BattleState  │  Cards  │  Entity    │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### 建议的模块拆分

```
Sources/
├── GameCore/                       # 纯逻辑层
│   │
│   │── Battle/                     # 战斗系统 ✅（已有）
│   │   ├── BattleEngine.swift
│   │   ├── BattleState.swift
│   │   └── BattleStats.swift
│   │
│   ├── Cards/                      # 卡牌系统 ✅（已有）
│   │   ├── CardKind.swift
│   │   ├── Card.swift
│   │   └── StarterDeck.swift
│   │
│   ├── Entity/                     # 实体系统 ✅（已有）
│   │   └── Entity.swift
│   │
│   ├── Run/                        # 🆕 游戏会话系统
│   │   ├── RunState.swift          # 当前冒险状态
│   │   ├── RunProgress.swift       # 玩家进度
│   │   └── RunManager.swift        # 冒险管理器
│   │
│   ├── Map/                        # 🆕 地图系统
│   │   ├── MapNode.swift           # 地图节点
│   │   ├── MapPath.swift           # 路径定义
│   │   ├── MapGenerator.swift      # 地图生成
│   │   └── RoomType.swift          # 房间类型
│   │
│   ├── Enemies/                    # 🆕 敌人系统
│   │   ├── EnemyKind.swift         # 敌人种类枚举
│   │   ├── EnemyAI.swift           # 敌人 AI 行为
│   │   ├── EnemyIntent.swift       # 敌人意图
│   │   └── EnemyPool.swift         # 敌人池/遭遇表
│   │
│   ├── Relics/                     # 🆕 遗物系统
│   │   ├── RelicKind.swift         # 遗物种类
│   │   ├── RelicEffect.swift       # 遗物效果
│   │   └── RelicTrigger.swift      # 触发时机
│   │
│   ├── Rewards/                    # 🆕 奖励系统
│   │   ├── RewardType.swift        # 奖励类型
│   │   └── RewardGenerator.swift   # 奖励生成
│   │
│   ├── AI/                         # 🆕 AI 子系统（接口层）
│   │   ├── AIProvider.swift        # AI 服务协议
│   │   ├── AIPromptBuilder.swift   # 构建 AI 提示词
│   │   ├── AIDecision.swift        # AI 决策模型
│   │   └── GameStateEncoder.swift  # 游戏状态序列化
│   │
│   ├── Actions.swift               # ✅（已有）
│   ├── Events.swift                # ✅（已有）
│   ├── History.swift               # ✅（已有）
│   └── RNG.swift                   # ✅（已有）
│
└── GameCLI/                        # 表现层
    ├── Screens/                    # ✅（已有）
    │   ├── ...现有界面...
    │   ├── MapScreen.swift         # 🆕 地图界面
    │   ├── RewardScreen.swift      # 🆕 奖励选择界面
    │   ├── ShopScreen.swift        # 🆕 商店界面
    │   └── EventScreen.swift       # 🆕 事件界面
    ├── AI/                         # 🆕 AI 实现
    │   ├── OpenAIProvider.swift    # OpenAI API
    │   ├── ClaudeProvider.swift    # Claude API
    │   ├── LocalLLMProvider.swift  # 本地 LLM
    │   └── MockAIProvider.swift    # 测试用 Mock
    ├── Components/                 # ✅（已有）
    └── ...
```

---

## 🔑 关键设计决策

### 1. 会话 vs 战斗

| 概念 | 当前 | 目标 |
|------|------|------|
| 一次运行 | 一场战斗 | 一次完整冒险 |
| 状态持久化 | 无 | 需要保存进度 |
| 卡组变化 | 固定 | 动态增减 |

### 2. 敌人系统设计

**选项 A：枚举 + Switch（当前风格）**
```swift
enum EnemyKind {
    case jawWorm
    case cultist
    case slimeBoss
}

// 在 BattleEngine 中 switch 处理
```

**选项 B：Protocol + 独立类（类似杀戮尖塔）**
```swift
protocol EnemyBehavior {
    func chooseIntent(rng: SeededRNG) -> EnemyIntent
    func executeTurn(state: inout BattleState)
}

class JawWorm: EnemyBehavior { ... }
class Cultist: EnemyBehavior { ... }
```

### 3. 遗物系统设计

需要事件总线或观察者模式：

```swift
enum RelicTrigger {
    case onBattleStart
    case onTurnStart
    case onTurnEnd
    case onCardPlayed(Card)
    case onDamageDealt(Int)
    case onDamageTaken(Int)
    case onBlockGained(Int)
    case onEnemyKilled
    case onBattleEnd
}

protocol Relic {
    var kind: RelicKind { get }
    func trigger(_ event: RelicTrigger, state: inout RunState)
}
```

### 4. 事件系统扩展

当前的 `BattleEvent` 只在战斗内使用，需要扩展：

```swift
// 战斗事件（现有）
enum BattleEvent { ... }

// 🆕 冒险事件
enum RunEvent {
    case enteredRoom(RoomType)
    case gainedCard(Card)
    case gainedRelic(Relic)
    case gainedGold(Int)
    case lostHP(Int)
    case healedHP(Int)
    case bossDefeated
    case runEnded(won: Bool)
}
```

---

## 📊（归档）开发优先级 & MVI 路线图

> 本节为历史记录/思路归档，**不作为执行依据**。协议驱动重构与实际实施顺序请以 `.cursor/plans/protocol-driven-design-plan.md` 为准。

### ~~P1：敌人系统 + AI~~ ✅ 已完成

| 步骤 | 内容 | 复杂度 | 状态 |
|------|------|--------|------|
| P1.1 | 添加第二个敌人（信徒） | ⭐ | ✅ |
| P1.2 | 创建 `EnemyKind` 枚举 | ⭐ | ✅ |
| P1.3 | 敌人不同攻击值 | ⭐ | ✅ |
| P1.4 | 敌人意图系统 | ⭐⭐ | ✅ |
| P1.5 | 敌人 AI 决策 | ⭐⭐⭐ | ✅ |
| P1.6 | 添加 5 种敌人（下颚虫、信徒、绿虱子、红虱子、酸液史莱姆） | ⭐⭐ | ✅ |

**验收结果**：
- ✅ 游戏随机出现 4 种敌人（从 Act1EnemyPool.weak 随机选择）
- ✅ 每种敌人有独特 AI 行为
- ✅ 测试脚本 4/4 通过，耗时 ~2秒
- 📄 详细方案：`.cursor/plans/P1-plan-A.md`

---

### ~~P2：地图程序生成~~ ✅ 已完成

| 步骤 | 内容 | 复杂度 | 状态 |
|------|------|--------|------|
| P2.1 | 创建地图数据模型（RoomType, MapNode, MapGenerator） | ⭐ | ✅ |
| P2.2 | 实现分支地图生成算法（每层2-4节点，随机连接） | ⭐⭐ | ✅ |
| P2.3 | 创建 RunState 冒险状态管理 | ⭐ | ✅ |
| P2.4 | 添加地图界面 MapScreen（显示分支路径） | ⭐ | ✅ |
| P2.5 | 实现连续战斗与生命值保持 | ⭐ | ✅ |
| P2.6 | 添加休息节点（恢复30% HP） | ⭐ | ✅ |
| P2.7 | Boss 节点与通关逻辑 | ⭐⭐ | ✅ |

**验收结果**：
- ✅ 游戏有完整的一层地图（15层分支节点）
- ✅ 玩家可在分叉路径中选择路线
- ✅ 连续战斗间生命值保持
- ✅ 休息节点恢复30%最大HP
- ✅ Boss节点击败后通关
- 📄 详细方案：`.cursor/plans/P2-map-generation-plan.md`

---

### P3：奖励系统 ⭐⭐

| 步骤 | 内容 | 复杂度 | 预计时间 |
|------|------|--------|----------|
| P3.1 | 战斗胜利后显示奖励界面 | ⭐ | 15分钟 |
| P3.2 | 奖励 3 选 1 卡牌 | ⭐ | 30分钟 |
| P3.3 | 卡牌加入卡组 | ⭐ | 15分钟 |
| P3.4 | 金币奖励 | ⭐ | 15分钟 |
| P3.5 | 商店购买卡牌 | ⭐⭐ | 45分钟 |
| P3.6 | 商店移除卡牌 | ⭐ | 20分钟 |

**验收标准**：战斗后可获得新卡牌，卡组会变化

---

### P4：存档系统 ⭐⭐⭐

| 步骤 | 内容 | 复杂度 | 预计时间 |
|------|------|--------|----------|
| P4.1 | 设计 RunState 可序列化结构 | ⭐⭐ | 30分钟 |
| P4.2 | 战斗间自动保存 | ⭐ | 20分钟 |
| P4.3 | 继续上次冒险选项 | ⭐ | 20分钟 |
| P4.4 | 存档版本控制 | ⭐⭐ | 30分钟 |
| P4.5 | 多存档槽位 | ⭐⭐ | 30分钟 |

**验收标准**：可以随时退出，下次继续冒险

---

### P5：遗物系统 ⭐⭐⭐

| 步骤 | 内容 | 复杂度 | 预计时间 |
|------|------|--------|----------|
| P5.1 | 创建 `Relic` 协议 | ⭐ | 15分钟 |
| P5.2 | 实现触发事件系统 | ⭐⭐ | 45分钟 |
| P5.3 | 实现第一个遗物（战斗开始+1能量） | ⭐ | 20分钟 |
| P5.4 | 遗物 UI 显示 | ⭐ | 20分钟 |
| P5.5 | Boss 掉落遗物 | ⭐ | 20分钟 |
| P5.6 | 实现 5 个基础遗物 | ⭐⭐ | 1小时 |

**验收标准**：玩家可获得遗物，遗物有实际效果

---

### P6：多角色 ⭐⭐

| 步骤 | 内容 | 复杂度 | 预计时间 |
|------|------|--------|----------|
| P6.1 | 创建角色选择界面 | ⭐ | 20分钟 |
| P6.2 | 设计第二角色（如静默猎手） | ⭐⭐ | 30分钟 |
| P6.3 | 角色专属起始牌组 | ⭐ | 20分钟 |
| P6.4 | 角色专属起始遗物 | ⭐ | 15分钟 |
| P6.5 | 角色专属卡池 | ⭐⭐ | 1小时 |

**验收标准**：可选择不同角色开始冒险

---

### P7：AI 集成 ⭐⭐⭐

**依赖**：P1（敌人系统）、P3（奖励系统）、P5（遗物系统）基本完成

#### 架构设计

```
Sources/
├── GameCore/
│   ├── AI/                         # AI 子系统（接口层）
│   │   ├── AIProvider.swift        # AI 服务协议
│   │   ├── AIPromptBuilder.swift   # 构建 AI 提示词
│   │   ├── AIDecision.swift        # AI 决策模型
│   │   └── GameStateEncoder.swift  # 游戏状态序列化
│   └── ...
│
└── GameCLI/
    ├── AI/                         # AI 实现（具体实现）
    │   ├── OpenAIProvider.swift    # OpenAI API
    │   ├── ClaudeProvider.swift    # Claude API
    │   ├── LocalLLMProvider.swift  # 本地 LLM
    │   └── MockAIProvider.swift    # 测试用 Mock
    └── ...
```

#### 核心接口

```swift
// AI 服务协议
protocol AIProvider: Sendable {
    func decide(context: GameContext, question: AIQuestion) async throws -> AIDecision
}

// AI 可回答的问题类型
enum AIQuestion {
    case enemyNextMove           // 敌人决策
    case suggestPlayerAction     // 玩家建议
    case generateEventText       // 生成事件
    case evaluateGameState       // 评估局势
}
```

#### MVI 步骤

| 步骤 | 内容 | 复杂度 | 预计时间 |
|------|------|--------|----------|
| P7.1 | 设计 `AIProvider` 协议和数据结构 | ⭐⭐ | 30分钟 |
| P7.2 | 实现 `MockAIProvider`（随机决策） | ⭐ | 20分钟 |
| P7.3 | 实现 `OpenAIProvider` | ⭐⭐ | 1小时 |
| P7.4 | AI 敌人决策集成 | ⭐⭐ | 45分钟 |
| P7.5 | AI 玩家助手（按 'a' 获取建议） | ⭐ | 30分钟 |
| P7.6 | AI 对战模式（观战 AI 自动打牌） | ⭐⭐ | 1小时 |
| P7.7 | AI 生成事件文本 | ⭐⭐ | 45分钟 |
| P7.8 | 本地 LLM 支持（llama.cpp / MLX） | ⭐⭐⭐ | 2小时 |

**验收标准**：
- 敌人可使用 AI 进行智能决策
- 玩家可按 'a' 键获取 AI 策略建议
- 支持 AI 自动对战模式
- 支持 AI 生成随机事件

#### API 费用参考

| 模型 | 大致费用 | 特点 |
|------|----------|------|
| GPT-4o-mini | ~$0.0001/请求 | 便宜，响应快 |
| Claude Haiku | ~$0.0001/请求 | 便宜，推理好 |
| 本地 LLM | 免费 | 离线，需要硬件 |

---

## ✅ 设计决策（已确定）

| 问题 | 决策 | 说明 |
|------|------|------|
| 敌人 AI 复杂度 | **真正的 AI 决策** | 敌人有智能行为，而非固定模式 |
| 地图生成 | **程序生成** | 每次冒险生成不同地图 |
| 存档系统 | **支持中途保存** | 可以随时退出，下次继续 |
| 多角色 | **支持多个角色** | 不只做铁甲战士 |

### 设计影响

**敌人 AI 决策**意味着：
- 敌人需要评估当前局势
- 根据玩家状态选择最优行动
- 可能需要简单的决策树或状态机

**程序生成地图**意味着：
- 需要地图生成算法
- 保证生成的地图可通关
- 使用种子确保可复现

**支持中途保存**意味着：
- 需要完整的状态序列化
- 需要设计存档文件格式
- 需要考虑版本兼容性

**多角色**意味着：
- 角色选择界面
- 不同角色有不同的起始卡组/遗物
- 角色专属卡牌库

---

## 📝 修订历史

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-01-01 | v0.1 | 初稿 |

