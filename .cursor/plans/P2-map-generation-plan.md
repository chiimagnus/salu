# P2 地图程序生成实现计划

> 创建时间：2026-01-03
> 状态：待实施
> 预计总时间：4-5 小时

---

## 📋 概述

本文档详细描述 P2 地图程序生成功能的实现计划。目标是将游戏从单场战斗扩展为具有完整地图系统的冒险模式。

### 当前状态

```
当前流程：主菜单 → 单场战斗 → 结果 → 主菜单
目标流程：主菜单 → 地图选择 → [战斗/休息/Boss...] × N → 冒险结束
```

### 验收标准

- ✅ 游戏有完整的一层地图（15 个节点）
- ✅ 玩家可在分叉路径中选择路线
- ✅ 连续战斗间生命值保持
- ✅ 休息节点可恢复生命
- ✅ Boss 节点击败后冒险结束

---

## 🏗️ 架构设计

### 新增文件结构

```
Sources/
├── GameCore/
│   ├── Map/                        # 🆕 地图系统
│   │   ├── RoomType.swift          # 房间类型枚举
│   │   ├── MapNode.swift           # 地图节点模型
│   │   ├── MapGenerator.swift      # 地图生成器
│   │   └── MapPath.swift           # 路径定义
│   │
│   ├── Run/                        # 🆕 冒险会话系统
│   │   ├── RunState.swift          # 冒险状态
│   │   └── RunManager.swift        # 冒险管理器
│   │
│   └── Enemies/
│       └── EnemyPool.swift         # 扩展：Boss 敌人池
│
└── GameCLI/
    ├── Screens/
    │   └── MapScreen.swift         # 🆕 地图界面
    │
    └── GameCLI.swift               # 修改：冒险循环
```

### 核心类型设计

#### RoomType（房间类型）
```swift
public enum RoomType: Sendable, Equatable {
    case battle         // 战斗（弱敌人）
    case elite          // 精英战斗（强敌人）
    case rest           // 休息（恢复生命）
    case boss           // Boss 战斗
    case start          // 起点
}
```

#### MapNode（地图节点）
```swift
public struct MapNode: Identifiable, Sendable {
    public let id: String
    public let row: Int             // 层数（0=起点, 15=Boss）
    public let column: Int          // 列位置
    public let roomType: RoomType   // 房间类型
    public var connections: [String] // 连接的下一层节点 ID
    public var isCompleted: Bool    // 是否已完成
    public var isAccessible: Bool   // 是否可进入
}
```

#### RunState（冒险状态）
```swift
public struct RunState: Sendable {
    public var player: Entity           // 玩家（HP 保持）
    public var deck: [Card]             // 当前牌组
    public var map: [MapNode]           // 地图节点
    public var currentNodeId: String?   // 当前位置
    public var floor: Int               // 当前楼层（Act）
    public var seed: UInt64             // 随机种子
    public var isOver: Bool             // 冒险是否结束
    public var won: Bool                // 是否通关
}
```

---

## 📊 实施步骤

### 阶段一：分支地图系统（P2.1 - P2.4）

> **重要调整**：直接实现分支地图，让玩家可以选择路线

#### P2.1 创建地图数据模型 ⭐ [20分钟]

**目标**：创建地图数据模型，支持分支节点地图

**新增文件**：

1. `Sources/GameCore/Map/RoomType.swift`
```swift
/// 房间类型
public enum RoomType: String, Sendable, Equatable, CaseIterable {
    case start = "start"        // 起点
    case battle = "battle"      // 普通战斗
    case elite = "elite"        // 精英战斗
    case rest = "rest"          // 休息点
    case boss = "boss"          // Boss
    
    public var displayName: String { ... }
    public var icon: String { ... }
}
```

2. `Sources/GameCore/Map/MapNode.swift`
```swift
/// 地图节点
public struct MapNode: Identifiable, Sendable, Equatable {
    public let id: String
    public let row: Int
    public let column: Int
    public let roomType: RoomType
    public var connections: [String]
    public var isCompleted: Bool = false
    public var isAccessible: Bool = false
}
```

3. `Sources/GameCore/Map/MapGenerator.swift`
```swift
/// 地图生成器
public struct MapGenerator {
    /// 生成线性地图（5 个战斗节点）
    public static func generateLinear(seed: UInt64) -> [MapNode] { ... }
}
```

**验证点**：
- [ ] `swift build` 成功
- [ ] 可创建分支地图并访问节点

---

#### P2.2 实现分支地图生成算法 ⭐⭐ [40分钟]

**目标**：生成分支地图，每层 2-3 个节点，节点间有随机连接

**在 MapGenerator.swift 中实现**：
```swift
public static func generateBranching(seed: UInt64, rows: Int = 15) -> [MapNode] {
    var rng = SeededRNG(seed: seed)
    var nodes: [MapNode] = []
    
    // 第 0 层：起点（1个节点）
    // 第 1-13 层：每层 2-3 个节点
    // 第 14 层：Boss（1个节点）
    
    // 节点连接规则：
    // - 每个节点至少连接 1 个下一层节点
    // - 每个节点最多连接 2 个下一层节点
    // - 确保所有路径都能到达 Boss
}
```

**验证点**：
- [ ] `swift build` 成功
- [ ] 地图有正确的层数和节点数
- [ ] 所有路径都可到达 Boss

---

#### P2.3 创建 RunState 冒险状态管理 ⭐ [25分钟]

**目标**：创建冒险状态，管理玩家HP保持和地图进度

---

#### P2.4 添加地图界面 ⭐ [30分钟]

**目标**：创建 CLI 地图显示界面，显示分支路径和可选节点

**新增文件**：

1. `Sources/GameCLI/Screens/MapScreen.swift`
```swift
/// 地图界面
enum MapScreen {
    static func show(runState: RunState) { ... }
    static func buildMapDisplay(nodes: [MapNode], currentId: String?) -> [String] { ... }
}
```

**修改文件**：

1. `Sources/GameCLI/Screens.swift` - 添加 showMap() 入口
2. `Sources/GameCLI/GameCLI.swift` - 添加冒险模式入口

**界面预览**：
```
═══════════════════════════════════════════════
  🗺️ 第一层地图   🎲 种子: 12345
═══════════════════════════════════════════════

  [👹] ← Boss
    │
  [💤]    [⚔️]
    │    ╱
  [⚔️] ←── 当前位置
    │
  [⚔️]
    │
  [🚪] ← 起点（已完成）

═══════════════════════════════════════════════
  选择下一个节点: [1] 战斗  [2] 休息
═══════════════════════════════════════════════
```

**验证点**：
- [ ] `swift build` 成功
- [ ] 主菜单可进入地图模式
- [ ] 地图正确显示节点和当前位置

---

#### P2.3 连续战斗与生命值保持 ⭐ [20分钟]

**目标**：实现连续战斗，玩家 HP 在战斗间保持

**新增文件**：

1. `Sources/GameCore/Run/RunState.swift`
```swift
/// 冒险状态
public struct RunState: Sendable {
    public var player: Entity
    public var deck: [Card]
    public var map: [MapNode]
    public var currentNodeId: String?
    public let seed: UInt64
    public var isOver: Bool = false
    public var won: Bool = false
    
    /// 从战斗结果更新玩家状态
    public mutating func updateFromBattle(playerHP: Int) { ... }
    
    /// 标记当前节点完成，解锁下一层
    public mutating func completeCurrentNode() { ... }
}
```

**修改文件**：

1. `Sources/GameCLI/GameCLI.swift`
   - 添加 `runLoop()` 冒险主循环
   - 修改 `startNewBattle()` 接受玩家状态

2. `Sources/GameCore/Battle/BattleEngine.swift`
   - 添加构造器接受外部玩家 Entity

**验证点**：
- [ ] `swift build` 成功
- [ ] 第一场战斗后，玩家 HP 保持到第二场
- [ ] 玩家死亡时冒险结束

---

### 阶段二：休息与 Boss 系统（P2.4, P2.7）

#### P2.4 添加休息节点 ⭐ [20分钟]

**目标**：休息节点可恢复 30% 最大生命值

**修改文件**：

1. `Sources/GameCore/Run/RunState.swift`
```swift
/// 在休息点恢复生命
public mutating func restAtNode() {
    let healAmount = player.maxHP * 30 / 100
    player.currentHP = min(player.maxHP, player.currentHP + healAmount)
}
```

2. `Sources/GameCLI/Screens/MapScreen.swift`
   - 添加休息选项界面

3. `Sources/GameCLI/GameCLI.swift`
   - 处理休息节点逻辑

**验证点**：
- [ ] `swift build` 成功
- [ ] 进入休息节点可恢复 HP
- [ ] 休息后正确标记节点完成

---

#### P2.7 Boss 节点 ⭐⭐ [30分钟]

**目标**：添加 Boss 战斗，击败后冒险胜利

**新增文件**：

1. `Sources/GameCore/Enemies/BossData.swift`
```swift
/// Boss 数据
public struct BossData {
    public let kind: EnemyKind
    public let minHP: Int
    public let maxHP: Int
    public let baseAttackDamage: Int
}
```

**修改文件**：

1. `Sources/GameCore/Enemies/EnemyKind.swift`
   - 添加 Boss 敌人种类（如 `slimeBoss`）

2. `Sources/GameCore/Enemies/EnemyPool.swift`
   - 添加 Boss 池

3. `Sources/GameCore/Map/MapGenerator.swift`
   - 确保最后一个节点是 Boss

4. `Sources/GameCLI/GameCLI.swift`
   - Boss 战斗胜利后显示通关界面

**验证点**：
- [ ] `swift build` 成功
- [ ] 击败 Boss 后显示通关
- [ ] Boss 有独特的 AI 行为

---

### 阶段三：分叉路径系统（P2.5 - P2.6）

#### P2.5 分叉路径 ⭐⭐ [45分钟]

**目标**：玩家可在分叉路径中选择

**修改文件**：

1. `Sources/GameCore/Map/MapGenerator.swift`
```swift
/// 生成分叉地图
public static func generateBranching(seed: UInt64) -> [MapNode] {
    // 每层 2-3 个节点
    // 节点间有随机连接
}
```

2. `Sources/GameCore/Map/MapNode.swift`
   - 确保 connections 支持多个目标

3. `Sources/GameCLI/Screens/MapScreen.swift`
   - 显示分叉路径
   - 让玩家选择目标节点

**验证点**：
- [ ] `swift build` 成功
- [ ] 地图显示分叉路径
- [ ] 玩家可选择不同路线

---

#### P2.6 程序生成完整地图 ⭐⭐⭐ [1.5小时]

**目标**：生成符合杀戮尖塔规则的完整地图

**地图规则**：
- 15 层：第 0 层起点，第 1-14 层房间，第 15 层 Boss
- 每层 2-4 个节点
- 节点向上连接 1-2 个节点
- 房间类型分布：
  - 第 1-5 层：普通战斗为主
  - 第 6 层：休息点
  - 第 9 层：精英战斗
  - 第 12 层：休息点
  - 第 15 层：Boss

**修改文件**：

1. `Sources/GameCore/Map/MapGenerator.swift`
```swift
public static func generateFullMap(seed: UInt64) -> [MapNode] {
    var rng = SeededRNG(seed: seed)
    var nodes: [MapNode] = []
    
    // 生成每层节点
    for row in 0...15 {
        let columnCount = decideColumnCount(row: row, rng: &rng)
        for col in 0..<columnCount {
            let roomType = decideRoomType(row: row, col: col, rng: &rng)
            let node = MapNode(id: "\(row)_\(col)", row: row, column: col, roomType: roomType)
            nodes.append(node)
        }
    }
    
    // 生成连接
    connectNodes(&nodes, rng: &rng)
    
    return nodes
}
```

2. `Sources/GameCLI/Screens/MapScreen.swift`
   - 优化大地图显示

**验证点**：
- [ ] `swift build` 成功
- [ ] 地图有 15 层
- [ ] 房间类型分布合理
- [ ] 所有路径都可到达 Boss

---

## 🔧 实施顺序（已调整）

> **调整说明**：直接实现分支地图，跳过线性地图阶段

```
P2.1 创建地图数据模型（RoomType, MapNode, MapGenerator）
  ↓ swift build 验证
P2.2 实现分支地图生成算法（每层2-3节点，随机连接）
  ↓ swift build 验证
P2.3 创建 RunState 冒险状态管理
  ↓ swift build 验证
P2.4 添加地图界面 MapScreen（显示分支路径）
  ↓ swift build 验证 + 地图显示测试
P2.5 实现连续战斗与生命值保持
  ↓ swift build 验证 + 游戏测试
P2.6 添加休息节点（恢复30% HP）
  ↓ swift build 验证
P2.7 添加 Boss 节点与通关逻辑
  ↓ swift build 验证 + 完整冒险测试
```

---

## ✅ 检查清单

### GameCore 检查
- [ ] 无 `print()` 语句
- [ ] 所有类型标记 `public` 和 `Sendable`
- [ ] 使用 SeededRNG 保证可复现
- [ ] 无 Foundation 导入（除 History.swift）

### GameCLI 检查
- [ ] 颜色使用 Terminal 常量
- [ ] 屏幕刷新使用清屏模式
- [ ] 用户可见文本使用中文
- [ ] 后台运行 swift build 测试

### 功能检查
- [ ] 主菜单可进入冒险模式
- [ ] 地图正确显示当前位置
- [ ] 战斗后 HP 保持
- [ ] 休息恢复 HP
- [ ] 击败 Boss 通关
- [ ] 玩家死亡游戏结束

---

## 📝 备注

1. **向后兼容**：保留"快速战斗"选项（原有的单场战斗模式）
2. **种子复现**：地图生成使用种子，确保相同种子产生相同地图
3. **渐进实施**：每个步骤完成后验证 build，避免积累错误

---

## 📅 修订历史

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-01-03 | v1.0 | 初稿 |

