# P2 地图程序生成实现计划

> 创建时间：2026-01-03
> 状态：✅ 已完成
> 实际时间：约 2 小时

---

## 📋 概述

本文档详细描述 P2 地图程序生成功能的实现计划。目标是将游戏从单场战斗扩展为具有完整地图系统的冒险模式。

### 当前状态

```
原有流程：主菜单 → 单场战斗 → 结果 → 主菜单
现有流程：主菜单 → 开始冒险 → 地图选择 → [战斗/休息/Boss...] × N → 冒险结束
```

### 验收标准

- ✅ 游戏有完整的一层地图（15 层节点）
- ✅ 玩家可在分叉路径中选择路线
- ✅ 连续战斗间生命值保持
- ✅ 休息节点可恢复生命（30% 最大 HP）
- ✅ Boss 节点击败后冒险结束

---

## 🏗️ 架构设计

### 新增文件结构（实际）

```
Sources/
├── GameCore/
│   ├── Map/                        # ✅ 地图系统
│   │   ├── RoomType.swift          # ✅ 房间类型枚举
│   │   ├── MapNode.swift           # ✅ 地图节点模型
│   │   └── MapGenerator.swift      # ✅ 分支地图生成器
│   │
│   └── Run/                        # ✅ 冒险会话系统
│       └── RunState.swift          # ✅ 冒险状态管理
│
└── GameCLI/
    ├── Screens/
    │   └── MapScreen.swift         # ✅ 地图界面
    │
    ├── Screens.swift               # ✅ 添加地图入口
    ├── MainMenuScreen.swift        # ✅ 更新主菜单
    └── GameCLI.swift               # ✅ 冒险循环
```

### 核心类型设计

#### RoomType（房间类型）✅
```swift
public enum RoomType: String, Sendable, Equatable, CaseIterable {
    case start = "start"    // 起点
    case battle = "battle"  // 普通战斗
    case elite = "elite"    // 精英战斗
    case rest = "rest"      // 休息点
    case boss = "boss"      // Boss
    
    public var displayName: String { ... }
    public var icon: String { ... }
}
```

#### MapNode（地图节点）✅
```swift
public struct MapNode: Identifiable, Sendable, Equatable {
    public let id: String
    public let row: Int             // 层数（0=起点, 14=Boss）
    public let column: Int          // 列位置
    public let roomType: RoomType   // 房间类型
    public var connections: [String] // 连接的下一层节点 ID
    public var isCompleted: Bool    // 是否已完成
    public var isAccessible: Bool   // 是否可进入
}
```

#### RunState（冒险状态）✅
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

#### P2.1 创建地图数据模型 ⭐ ✅

**目标**：创建地图数据模型，支持分支节点地图

**新增文件**：
- ✅ `Sources/GameCore/Map/RoomType.swift`
- ✅ `Sources/GameCore/Map/MapNode.swift`
- ✅ `Sources/GameCore/Map/MapGenerator.swift`

---

#### P2.2 实现分支地图生成算法 ⭐⭐ ✅

**目标**：生成分支地图，每层 2-4 个节点，节点间有随机连接

**实现内容**：
- ✅ 15 层地图（第 0 层起点，第 14 层 Boss）
- ✅ 每层 2-4 个节点（起点和 Boss 层只有 1 个）
- ✅ 每个节点连接 1-2 个下一层节点
- ✅ 确保所有节点都可到达
- ✅ 房间类型按层分布（休息点在第 6、12 层，精英在第 8-10 层）

---

#### P2.3 创建 RunState 冒险状态管理 ⭐ ✅

**目标**：创建冒险状态，管理玩家HP保持和地图进度

**新增文件**：
- ✅ `Sources/GameCore/Run/RunState.swift`

**实现功能**：
- ✅ `newRun(seed:)` - 创建新冒险
- ✅ `enterNode(_:)` - 进入节点
- ✅ `completeCurrentNode()` - 完成节点，解锁下一层
- ✅ `updateFromBattle(playerHP:)` - 更新战斗后玩家状态
- ✅ `restAtNode()` - 休息恢复 HP

---

#### P2.4 添加地图界面 ⭐ ✅

**目标**：创建 CLI 地图显示界面，显示分支路径和可选节点

**新增文件**：
- ✅ `Sources/GameCLI/Screens/MapScreen.swift`

**修改文件**：
- ✅ `Sources/GameCLI/Screens.swift` - 添加 showMap() 入口
- ✅ `Sources/GameCLI/Screens/MainMenuScreen.swift` - 更新主菜单
- ✅ `Sources/GameCLI/GameCLI.swift` - 添加冒险循环

---

### 阶段二：战斗与休息系统（P2.5 - P2.6）

#### P2.5 实现连续战斗与生命值保持 ⭐ ✅

**目标**：实现连续战斗，玩家 HP 在战斗间保持

**实现内容**：
- ✅ `handleBattleNode()` - 处理战斗节点
- ✅ 战斗使用冒险中的玩家状态
- ✅ 战斗后更新玩家 HP
- ✅ 玩家死亡时冒险结束

---

#### P2.6 添加休息节点 ⭐ ✅

**目标**：休息节点可恢复 30% 最大生命值

**实现内容**：
- ✅ `handleRestNode()` - 处理休息节点
- ✅ `MapScreen.showRestOptions()` - 休息选项界面
- ✅ `MapScreen.showRestResult()` - 休息结果显示

---

### 阶段三：Boss 系统（P2.7）

#### P2.7 Boss 节点与通关逻辑 ⭐⭐ ✅

**目标**：添加 Boss 战斗，击败后冒险胜利

**实现内容**：
- ✅ `handleBossNode()` - 处理 Boss 节点
- ✅ Boss 战斗胜利后显示通关界面
- ✅ Boss 战斗失败冒险结束

**注意**：目前使用 `slimeMediumAcid` 作为临时 Boss，未来可添加专属 Boss 敌人

---

## ✅ 检查清单

### GameCore 检查
- [x] 无 `print()` 语句
- [x] 所有类型标记 `public` 和 `Sendable`
- [x] 使用 SeededRNG 保证可复现
- [x] 无 Foundation 导入（除 History.swift）

### GameCLI 检查
- [x] 颜色使用 Terminal 常量
- [x] 屏幕刷新使用清屏模式
- [x] 用户可见文本使用中文
- [x] swift build 验证通过

### 功能检查
- [x] 主菜单可进入冒险模式
- [x] 地图正确显示分支路径（杀戮尖塔风格路径选择）
- [x] 玩家只能选择当前节点连接的下一层节点
- [x] 地图节点状态清晰区分：[✓]已完成 / [黄色]可选择 / [灰色]不可选
- [x] 战斗后 HP 保持
- [x] 休息恢复 HP（30%）
- [x] 击败 Boss 通关
- [x] 玩家死亡冒险结束

---

## 📝 备注

1. **路径选择**：✅ 杀戮尖塔风格，玩家只能选择当前节点连接的下一层节点
2. **种子复现**：✅ 地图生成使用种子，确保相同种子产生相同地图
3. **主菜单简化**：✅ 移除"快速战斗"选项，只保留冒险模式入口
4. **未实现项**：
   - `MapPath.swift` - 连接信息已在 MapNode 中实现
   - `RunManager.swift` - 功能已在 GameCLI 中实现
   - `BossData.swift` - 使用现有敌人作为临时 Boss

---

## 🔮 后续优化建议

1. **添加专属 Boss 敌人**：创建 `slimeBoss` 等专属 Boss 类型
2. **优化地图显示**：改进分支连接线的可视化
3. **添加精英战斗奖励**：精英战斗后获得额外奖励
4. **添加事件节点**：随机事件选择

---

## 📅 修订历史

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-01-03 | v1.0 | 初稿 |
| 2026-01-03 | v1.1 | 完成实施，更新状态 |
