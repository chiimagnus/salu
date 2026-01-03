# P2 地图系统实现计划 A

> 创建时间：2026-01-03  
> 状态：执行中  
> 前置条件：P1（敌人系统）已完成 ✅

---

## 📋 目标概述

将 Salu 从单场战斗游戏扩展为带有地图系统的冒险游戏，玩家可以在地图上选择路径，经历多场战斗，生命值在战斗间保持。

**验收标准**：游戏有完整的一层地图，玩家可选择路径，经历连续战斗。

---

## 🏗️ 架构设计

### 新增模块结构

```
Sources/
├── GameCore/
│   ├── Map/                        # 🆕 地图系统
│   │   ├── MapNode.swift           # 地图节点（房间）
│   │   ├── MapPath.swift           # 路径连接
│   │   ├── MapGenerator.swift      # 地图生成器
│   │   └── RoomType.swift          # 房间类型枚举
│   │
│   ├── Run/                        # 🆕 游戏会话系统
│   │   ├── RunState.swift          # 当前冒险状态
│   │   ├── RunProgress.swift       # 玩家进度追踪
│   │   └── RunManager.swift        # 冒险管理器
│   │
│   └── ...（现有模块）
│
└── GameCLI/
    ├── Screens/
    │   ├── MapScreen.swift         # 🆕 地图界面
    │   ├── RestScreen.swift        # 🆕 休息界面
    │   └── ...（现有界面）
    └── ...
```

---

## 📊 实现步骤（MVI 增量开发）

### P2.1: 线性地图（固定 5 个战斗节点）⭐

**目标**：创建最简单的线性地图，5 个战斗依次进行。

**预计时间**：20 分钟

#### 实现内容

1. **创建 `RoomType` 枚举**
   ```swift
   // Sources/GameCore/Map/RoomType.swift
   public enum RoomType: String, Sendable {
       case battle = "⚔️"      // 战斗房间
       case rest = "🔥"        // 休息房间
       case boss = "👹"        // Boss 房间
       
       var displayName: String {
           switch self {
           case .battle: return "战斗"
           case .rest: return "休息"
           case .boss: return "Boss"
           }
       }
   }
   ```

2. **创建 `MapNode` 结构**
   ```swift
   // Sources/GameCore/Map/MapNode.swift
   public struct MapNode: Identifiable, Sendable {
       public let id: Int              // 节点 ID
       public let floor: Int           // 楼层（Y 坐标）
       public let roomType: RoomType   // 房间类型
       public var isVisited: Bool      // 是否已访问
       public var isCurrentPosition: Bool  // 是否是当前位置
       
       public init(id: Int, floor: Int, roomType: RoomType) {
           self.id = id
           self.floor = floor
           self.roomType = roomType
           self.isVisited = false
           self.isCurrentPosition = false
       }
   }
   ```

3. **创建 `MapPath` 结构**
   ```swift
   // Sources/GameCore/Map/MapPath.swift
   public struct MapPath: Sendable {
       public let fromNodeId: Int  // 起始节点
       public let toNodeId: Int    // 目标节点
       
       public init(from: Int, to: Int) {
           self.fromNodeId = from
           self.toNodeId = to
       }
   }
   ```

4. **创建简单的线性地图生成器**
   ```swift
   // Sources/GameCore/Map/MapGenerator.swift
   public struct MapGenerator {
       /// 生成简单的线性地图（5 个战斗节点）
       public static func generateLinearMap() -> (nodes: [MapNode], paths: [MapPath]) {
           var nodes: [MapNode] = []
           var paths: [MapPath] = []
           
           // 创建 5 个战斗节点
           for i in 0..<5 {
               let node = MapNode(id: i, floor: i, roomType: .battle)
               nodes.append(node)
               
               // 连接到下一个节点
               if i < 4 {
                   paths.append(MapPath(from: i, to: i + 1))
               }
           }
           
           return (nodes, paths)
       }
   }
   ```

5. **更新 `GameCLI.swift` 以使用线性地图**
   - 修改 `startNewBattle()` 为 `startNewRun()`
   - 创建地图，但暂时只显示战斗界面（不显示地图 UI）

#### 测试方法
```bash
swift build && ./.build/debug/GameCLI
# 选择"开始新战斗"，验证可以连续进行 5 场战斗
```

---

### P2.2: 地图界面显示 ⭐

**目标**：在战斗间显示地图界面，标记当前位置。

**预计时间**：30 分钟

#### 实现内容

1. **创建 `MapScreen.swift`**
   ```swift
   // Sources/GameCLI/Screens/MapScreen.swift
   import GameCore
   import Foundation
   
   enum MapScreen {
       static func show(nodes: [MapNode], paths: [MapPath]) {
           Terminal.clear()
           
           print("""
           \(Terminal.bold)\(Terminal.cyan)
           ═══════════════════════════════════════════
                          地图
           ═══════════════════════════════════════════
           \(Terminal.reset)
           """)
           
           // 从上到下显示节点
           for node in nodes.sorted(by: { $0.floor > $1.floor }) {
               let icon = node.roomType.rawValue
               let marker = node.isCurrentPosition ? "➤ " : "  "
               let status = node.isVisited ? Terminal.dim : ""
               
               print("\(marker)\(status)楼层 \(node.floor): \(icon) \(node.roomType.displayName)\(Terminal.reset)")
           }
           
           print("\n\(Terminal.dim)按 Enter 继续...\(Terminal.reset)")
       }
   }
   ```

2. **在游戏流程中显示地图**
   - 在每场战斗前显示地图界面
   - 标记当前位置

#### 测试方法
```bash
swift build && ./.build/debug/GameCLI
# 验证在战斗前能看到地图界面
```

---

### P2.3: 连续战斗（生命值保持）⭐

**目标**：战斗结束后保持玩家生命值，继续下一场战斗。

**预计时间**：20 分钟

#### 实现内容

1. **创建 `RunState` 结构**
   ```swift
   // Sources/GameCore/Run/RunState.swift
   public struct RunState: Sendable {
       public var player: Entity           // 玩家状态（生命值保持）
       public var currentFloor: Int        // 当前楼层
       public var gold: Int                // 金币
       public var deck: [Card]             // 当前卡组
       
       // 地图相关
       public var nodes: [MapNode]
       public var paths: [MapPath]
       public var currentNodeId: Int
       
       public var isRunOver: Bool          // 冒险是否结束
       public var won: Bool                // 是否胜利
       
       public init(player: Entity, deck: [Card]) {
           self.player = player
           self.currentFloor = 0
           self.gold = 99
           self.deck = deck
           
           // 初始化线性地图
           let map = MapGenerator.generateLinearMap()
           self.nodes = map.nodes
           self.paths = map.paths
           self.currentNodeId = 0
           
           // 标记起始位置
           if !self.nodes.isEmpty {
               self.nodes[0].isCurrentPosition = true
           }
           
           self.isRunOver = false
           self.won = false
       }
       
       /// 获取当前节点
       public var currentNode: MapNode? {
           nodes.first { $0.id == currentNodeId }
       }
       
       /// 移动到下一个节点
       public mutating func moveToNextNode() {
           // 标记当前节点为已访问
           if let index = nodes.firstIndex(where: { $0.id == currentNodeId }) {
               nodes[index].isVisited = true
               nodes[index].isCurrentPosition = false
           }
           
           // 查找下一个节点（线性地图中就是 +1）
           let nextNodeId = currentNodeId + 1
           
           if let nextIndex = nodes.firstIndex(where: { $0.id == nextNodeId }) {
               nodes[nextIndex].isCurrentPosition = true
               currentNodeId = nextNodeId
               currentFloor = nodes[nextIndex].floor
           } else {
               // 没有更多节点，冒险结束
               isRunOver = true
               won = true
           }
       }
   }
   ```

2. **创建 `RunManager.swift`**
   ```swift
   // Sources/GameCore/Run/RunManager.swift
   public final class RunManager: @unchecked Sendable {
       public private(set) var runState: RunState
       private let seed: UInt64
       
       public init(seed: UInt64) {
           self.seed = seed
           let player = createDefaultPlayer()
           let deck = StarterDeck.ironclad
           self.runState = RunState(player: player, deck: deck)
       }
       
       /// 开始房间内容（战斗、休息等）
       public func enterCurrentRoom() -> RoomType {
           guard let node = runState.currentNode else {
               fatalError("No current node")
           }
           return node.roomType
       }
       
       /// 战斗结束后更新玩家状态
       public func updatePlayerAfterBattle(newHP: Int) {
           runState.player.currentHP = newHP
       }
       
       /// 移动到下一个房间
       public func proceedToNextRoom() {
           runState.moveToNextNode()
       }
   }
   ```

3. **修改 `GameCLI.swift` 主循环**
   - 将 `startNewBattle()` 改为 `startNewRun()`
   - 使用 `RunManager` 管理整个冒险
   - 在战斗间保持玩家生命值

#### 测试方法
```bash
swift build && ./.build/debug/GameCLI
# 第一场战斗结束后，验证第二场战斗时玩家生命值是第一场战斗后的值
```

---

### P2.4: 添加休息节点（恢复生命）⭐

**目标**：在第 3 层添加休息节点，玩家可以恢复生命值。

**预计时间**：20 分钟

#### 实现内容

1. **更新 `MapGenerator.generateLinearMap()`**
   ```swift
   public static func generateLinearMap() -> (nodes: [MapNode], paths: [MapPath]) {
       var nodes: [MapNode] = []
       var paths: [MapPath] = []
       
       // 楼层 0-1: 战斗
       nodes.append(MapNode(id: 0, floor: 0, roomType: .battle))
       nodes.append(MapNode(id: 1, floor: 1, roomType: .battle))
       
       // 楼层 2: 休息
       nodes.append(MapNode(id: 2, floor: 2, roomType: .rest))
       
       // 楼层 3-4: 战斗
       nodes.append(MapNode(id: 3, floor: 3, roomType: .battle))
       nodes.append(MapNode(id: 4, floor: 4, roomType: .battle))
       
       // 连接所有节点
       for i in 0..<4 {
           paths.append(MapPath(from: i, to: i + 1))
       }
       
       return (nodes, paths)
   }
   ```

2. **创建 `RestScreen.swift`**
   ```swift
   // Sources/GameCLI/Screens/RestScreen.swift
   enum RestScreen {
       static func show(player: Entity) {
           Terminal.clear()
           
           let healAmount = min(30, player.maxHP - player.currentHP)
           
           print("""
           \(Terminal.bold)\(Terminal.green)
           ═══════════════════════════════════════════
                         🔥 休息
           ═══════════════════════════════════════════
           \(Terminal.reset)
           
           你在篝火旁休息片刻...
           
           \(Terminal.green)生命值：\(player.currentHP) → \(player.currentHP + healAmount) / \(player.maxHP)\(Terminal.reset)
           \(Terminal.dim)（恢复 \(healAmount) 点生命）\(Terminal.reset)
           
           \(Terminal.dim)按 Enter 继续...\(Terminal.reset)
           """)
       }
   }
   ```

3. **在 `RunManager` 中添加休息功能**
   ```swift
   /// 休息恢复生命值
   public func rest() -> Int {
       let healAmount = min(30, runState.player.maxHP - runState.player.currentHP)
       runState.player.currentHP += healAmount
       return healAmount
   }
   ```

4. **在主循环中处理休息房间**
   ```swift
   // 在 GameCLI.swift 中
   let roomType = runManager.enterCurrentRoom()
   
   switch roomType {
   case .battle:
       // 进行战斗
       runBattle(runManager)
       
   case .rest:
       // 显示休息界面
       RestScreen.show(player: runManager.runState.player)
       _ = readLine()
       let healed = runManager.rest()
       runManager.proceedToNextRoom()
   
   case .boss:
       // Boss 战（暂时当作普通战斗）
       runBattle(runManager)
   }
   ```

#### 测试方法
```bash
swift build && ./.build/debug/GameCLI
# 完成前两场战斗后，第三层应该是休息，验证生命值恢复
```

---

### P2.5: 分叉路径（玩家可选择）⭐⭐

**目标**：在某些楼层提供多个选择，玩家可以选择走哪条路。

**预计时间**：45 分钟

#### 实现内容

1. **更新 `MapNode` 添加坐标**
   ```swift
   public struct MapNode: Identifiable, Sendable {
       public let id: Int
       public let floor: Int           // Y 坐标（楼层）
       public let column: Int          // X 坐标（列）
       public let roomType: RoomType
       public var isVisited: Bool
       public var isCurrentPosition: Bool
       public var isAccessible: Bool   // 是否可以访问（玩家能走到）
       
       public init(id: Int, floor: Int, column: Int, roomType: RoomType) {
           self.id = id
           self.floor = floor
           self.column = column
           self.roomType = roomType
           self.isVisited = false
           self.isCurrentPosition = false
           self.isAccessible = false
       }
   }
   ```

2. **创建分叉地图生成器**
   ```swift
   /// 生成有分叉的地图
   public static func generateBranchingMap() -> (nodes: [MapNode], paths: [MapPath]) {
       var nodes: [MapNode] = []
       var paths: [MapPath] = []
       var nodeId = 0
       
       // 楼层 0: 起始（1 个战斗）
       let node0 = MapNode(id: nodeId, floor: 0, column: 1, roomType: .battle)
       nodes.append(node0)
       nodeId += 1
       
       // 楼层 1: 分叉（2 个选择：战斗或战斗）
       let node1a = MapNode(id: nodeId, floor: 1, column: 0, roomType: .battle)
       nodes.append(node1a)
       nodeId += 1
       
       let node1b = MapNode(id: nodeId, floor: 1, column: 2, roomType: .battle)
       nodes.append(node1b)
       nodeId += 1
       
       // 连接 0 → 1a, 1b
       paths.append(MapPath(from: 0, to: 1))
       paths.append(MapPath(from: 0, to: 2))
       
       // 楼层 2: 汇合（1 个休息）
       let node2 = MapNode(id: nodeId, floor: 2, column: 1, roomType: .rest)
       nodes.append(node2)
       nodeId += 1
       
       // 连接 1a, 1b → 2
       paths.append(MapPath(from: 1, to: 3))
       paths.append(MapPath(from: 2, to: 3))
       
       // 楼层 3-4: 更多战斗
       let node3 = MapNode(id: nodeId, floor: 3, column: 1, roomType: .battle)
       nodes.append(node3)
       paths.append(MapPath(from: 3, to: 4))
       nodeId += 1
       
       let node4 = MapNode(id: nodeId, floor: 4, column: 1, roomType: .battle)
       nodes.append(node4)
       paths.append(MapPath(from: 4, to: 5))
       
       return (nodes, paths)
   }
   ```

3. **在 `RunState` 中添加获取可选路径的方法**
   ```swift
   /// 获取当前节点的所有下一步选择
   public func getNextNodes() -> [MapNode] {
       // 查找从当前节点出发的所有路径
       let nextNodeIds = paths
           .filter { $0.fromNodeId == currentNodeId }
           .map { $0.toNodeId }
       
       // 返回对应的节点
       return nodes.filter { nextNodeIds.contains($0.id) }
   }
   
   /// 移动到指定节点
   public mutating func moveToNode(_ nodeId: Int) {
       // 标记当前节点为已访问
       if let index = nodes.firstIndex(where: { $0.id == currentNodeId }) {
           nodes[index].isVisited = true
           nodes[index].isCurrentPosition = false
       }
       
       // 移动到新节点
       if let nextIndex = nodes.firstIndex(where: { $0.id == nodeId }) {
           nodes[nextIndex].isCurrentPosition = true
           currentNodeId = nodeId
           currentFloor = nodes[nextIndex].floor
       }
   }
   ```

4. **更新 `MapScreen` 显示选择**
   ```swift
   static func showWithChoices(
       nodes: [MapNode],
       paths: [MapPath],
       nextNodes: [MapNode]
   ) -> Int? {
       Terminal.clear()
       
       // 显示完整地图...
       
       print("\n\(Terminal.bold)选择下一个房间：\(Terminal.reset)\n")
       
       for (index, node) in nextNodes.enumerated() {
           let icon = node.roomType.rawValue
           print("  \(index + 1). \(icon) \(node.roomType.displayName)")
       }
       
       print("\n\(Terminal.yellow)输入选择 (1-\(nextNodes.count)): \(Terminal.reset)", terminator: "")
       
       guard let input = readLine(),
             let choice = Int(input),
             choice >= 1, choice <= nextNodes.count else {
           return nil
       }
       
       return nextNodes[choice - 1].id
   }
   ```

5. **在主循环中处理玩家选择**
   ```swift
   // 战斗或休息后，显示地图并让玩家选择下一步
   let nextNodes = runManager.runState.getNextNodes()
   
   if nextNodes.isEmpty {
       // 冒险结束
       runManager.runState.isRunOver = true
   } else if nextNodes.count == 1 {
       // 只有一个选择，自动前进
       runManager.runState.moveToNode(nextNodes[0].id)
   } else {
       // 多个选择，让玩家选
       if let chosenNodeId = MapScreen.showWithChoices(
           nodes: runManager.runState.nodes,
           paths: runManager.runState.paths,
           nextNodes: nextNodes
       ) {
           runManager.runState.moveToNode(chosenNodeId)
       }
   }
   ```

#### 测试方法
```bash
swift build && ./.build/debug/GameCLI
# 在第一场战斗后，应该看到两个选择
# 选择其中一个，验证能正确进入对应房间
```

---

### P2.6: 程序生成完整地图 ⭐⭐⭐

**目标**：随机生成杀戮尖塔风格的完整地图（15 层，多条路径）。

**预计时间**：1.5 小时

#### 实现内容

1. **创建地图生成参数**
   ```swift
   public struct MapConfig: Sendable {
       public let floors: Int              // 总楼层数
       public let minColumnsPerFloor: Int  // 每层最少节点数
       public let maxColumnsPerFloor: Int  // 每层最多节点数
       public let bossFloor: Int           // Boss 楼层
       public let restFloorInterval: Int   // 休息点间隔
       
       public static let act1 = MapConfig(
           floors: 15,
           minColumnsPerFloor: 3,
           maxColumnsPerFloor: 5,
           bossFloor: 14,
           restFloorInterval: 6
       )
   }
   ```

2. **实现程序生成算法**
   ```swift
   /// 生成完整的程序化地图
   public static func generateProceduralMap(config: MapConfig, seed: UInt64) 
       -> (nodes: [MapNode], paths: [MapPath]) {
       
       var rng = SeededRNG(seed: seed)
       var nodes: [MapNode] = []
       var paths: [MapPath] = []
       var nodeId = 0
       
       // 存储每层的节点 ID
       var floorNodes: [[Int]] = []
       
       for floor in 0..<config.floors {
           var currentFloorNodes: [Int] = []
           
           // 确定这层有多少个节点
           let nodeCount: Int
           if floor == 0 {
               nodeCount = 1  // 起始层只有 1 个节点
           } else if floor == config.bossFloor {
               nodeCount = 1  // Boss 层只有 1 个节点
           } else {
               nodeCount = rng.nextInt(
                   lowerBound: config.minColumnsPerFloor,
                   upperBound: config.maxColumnsPerFloor
               )
           }
           
           // 创建节点
           for col in 0..<nodeCount {
               let roomType = determineRoomType(
                   floor: floor,
                   bossFloor: config.bossFloor,
                   restInterval: config.restFloorInterval,
                   rng: &rng
               )
               
               let node = MapNode(
                   id: nodeId,
                   floor: floor,
                   column: col,
                   roomType: roomType
               )
               nodes.append(node)
               currentFloorNodes.append(nodeId)
               nodeId += 1
           }
           
           // 连接到上一层
           if floor > 0 {
               let previousFloorNodes = floorNodes[floor - 1]
               paths.append(contentsOf: generateConnections(
                   from: previousFloorNodes,
                   to: currentFloorNodes,
                   rng: &rng
               ))
           }
           
           floorNodes.append(currentFloorNodes)
       }
       
       return (nodes, paths)
   }
   
   /// 确定房间类型
   private static func determineRoomType(
       floor: Int,
       bossFloor: Int,
       restInterval: Int,
       rng: inout SeededRNG
   ) -> RoomType {
       if floor == bossFloor {
           return .boss
       }
       
       // 每隔一定楼层有休息点
       if floor > 0 && floor % restInterval == 0 {
           // 30% 概率是休息点
           return rng.nextInt(upperBound: 10) < 3 ? .rest : .battle
       }
       
       return .battle
   }
   
   /// 生成两层之间的连接
   private static func generateConnections(
       from previousNodes: [Int],
       to currentNodes: [Int],
       rng: inout SeededRNG
   ) -> [MapPath] {
       var paths: [MapPath] = []
       
       // 确保每个节点至少有一条入路和一条出路
       for currentNode in currentNodes {
           // 随机选择 1-2 个父节点连接
           let connectionCount = rng.nextInt(lowerBound: 1, upperBound: 3)
           let shuffledPrevious = rng.shuffled(previousNodes)
           
           for i in 0..<min(connectionCount, shuffledPrevious.count) {
               paths.append(MapPath(from: shuffledPrevious[i], to: currentNode))
           }
       }
       
       // 确保每个上层节点至少有一个出口
       for previousNode in previousNodes {
           let hasOutgoingPath = paths.contains { $0.fromNodeId == previousNode }
           if !hasOutgoingPath {
               let randomCurrent = currentNodes[rng.nextInt(upperBound: currentNodes.count)]
               paths.append(MapPath(from: previousNode, to: randomCurrent))
           }
       }
       
       return paths
   }
   ```

3. **更新 `RunState` 使用程序生成**
   ```swift
   public init(player: Entity, deck: [Card], seed: UInt64) {
       self.player = player
       self.currentFloor = 0
       self.gold = 99
       self.deck = deck
       
       // 生成程序化地图
       let map = MapGenerator.generateProceduralMap(
           config: .act1,
           seed: seed
       )
       self.nodes = map.nodes
       self.paths = map.paths
       self.currentNodeId = 0
       
       // 标记起始位置
       if !self.nodes.isEmpty {
           self.nodes[0].isCurrentPosition = true
           self.nodes[0].isAccessible = true
       }
       
       self.isRunOver = false
       self.won = false
   }
   ```

4. **改进 `MapScreen` 显示完整地图**
   ```swift
   static func showFullMap(nodes: [MapNode], paths: [MapPath]) {
       Terminal.clear()
       
       // 按楼层分组
       let maxFloor = nodes.map { $0.floor }.max() ?? 0
       let maxColumn = nodes.map { $0.column }.max() ?? 0
       
       print("""
       \(Terminal.bold)\(Terminal.cyan)
       ═══════════════════════════════════════════
                      地图 - 第一章
       ═══════════════════════════════════════════
       \(Terminal.reset)
       """)
       
       // 从上到下显示（Boss 在顶部）
       for floor in (0...maxFloor).reversed() {
           let floorNodes = nodes.filter { $0.floor == floor }
               .sorted { $0.column < $1.column }
           
           print("\n楼层 \(String(format: "%2d", floor)): ", terminator: "")
           
           for node in floorNodes {
               let icon = node.roomType.rawValue
               
               let style: String
               if node.isCurrentPosition {
                   style = Terminal.bold + Terminal.yellow
               } else if node.isVisited {
                   style = Terminal.dim
               } else if node.isAccessible {
                   style = Terminal.green
               } else {
                   style = Terminal.dim
               }
               
               print("\(style)\(icon)\(Terminal.reset) ", terminator: "")
           }
       }
       
       print("\n")
   }
   ```

#### 测试方法
```bash
swift build && ./.build/debug/GameCLI
# 验证地图随机生成，每次运行不同
# 验证有 15 层，包含战斗、休息、Boss
# 验证玩家可以选择路径到达 Boss
```

---

### P2.7: Boss 节点 ⭐⭐

**目标**：添加 Boss 战斗，Boss 更强大。

**预计时间**：30 分钟

#### 实现内容

1. **添加 Boss 敌人**
   ```swift
   // 在 EnemyKind.swift 中添加
   case slimeBossSmall = "slime_boss_small"
   
   public var displayName: String {
       switch self {
       // ...
       case .slimeBossSmall: return "史莱姆 Boss"
       }
   }
   ```

2. **在 `EnemyPool.swift` 添加 Boss 池**
   ```swift
   public static let bosses: [EnemyKind] = [
       .slimeBossSmall
   ]
   
   public static func randomBoss(rng: inout SeededRNG) -> EnemyKind {
       let index = rng.nextInt(upperBound: bosses.count)
       return bosses[index]
   }
   ```

3. **在 `EnemyData.swift` 添加 Boss 数据**
   ```swift
   case .slimeBossSmall:
       return EnemyData(
           minHP: 140,
           maxHP: 140,
           baseActions: [] // Boss AI 会特殊处理
       )
   ```

4. **实现 Boss AI**
   ```swift
   // 在 EnemyBehaviors.swift 中添加
   public struct SlimeBossAI: EnemyAI {
       public func chooseIntent(state: BattleState, rng: inout SeededRNG) -> EnemyIntent {
           // Boss 有更复杂的行为模式
           let turn = state.turn
           
           // 第一回合：大量格挡
           if turn == 1 {
               return .defend(amount: 15)
           }
           
           // 之后交替攻击和防御
           if turn % 2 == 0 {
               let damage = 12 + rng.nextInt(upperBound: 4)
               return .attack(damage: damage)
           } else {
               return .defend(amount: 10)
           }
       }
   }
   ```

5. **在战斗开始时检测 Boss**
   ```swift
   // 在 BattleScreen 中显示 Boss 标题
   if state.enemy.kind == .slimeBossSmall {
       print("""
       \(Terminal.bold)\(Terminal.red)
       ╔══════════════════════════════════════════╗
       ║            ⚠️  BOSS 战斗！             ║
       ╚══════════════════════════════════════════╝
       \(Terminal.reset)
       """)
   }
   ```

6. **在 `RunManager` 中根据房间类型选择敌人**
   ```swift
   public func createBattleForCurrentRoom(rng: inout SeededRNG) -> BattleEngine {
       guard let node = runState.currentNode else {
           fatalError("No current node")
       }
       
       let enemyKind: EnemyKind
       if node.roomType == .boss {
           enemyKind = Act1EnemyPool.randomBoss(rng: &rng)
       } else {
           enemyKind = Act1EnemyPool.randomWeak(rng: &rng)
       }
       
       let enemy = createEnemy(kind: enemyKind, rng: &rng)
       
       return BattleEngine(
           player: runState.player,
           enemy: enemy,
           deck: runState.deck,
           seed: rng.seed
       )
   }
   ```

#### 测试方法
```bash
swift build && ./.build/debug/GameCLI
# 完成 14 场战斗后，第 15 层应该是 Boss
# 验证 Boss 有更高生命值和不同行为
```

---

## ✅ 验收标准

完成所有步骤后，游戏应该满足：

1. **地图生成** ✓
   - [x] 15 层程序生成地图
   - [x] 每层 3-5 个节点
   - [x] 随机分布战斗和休息
   - [x] 最后一层是 Boss

2. **地图导航** ✓
   - [x] 显示完整地图界面
   - [x] 标记当前位置、已访问、可访问路径
   - [x] 玩家可以选择路径
   - [x] 自动前进（只有一条路时）

3. **游戏进度** ✓
   - [x] 生命值在战斗间保持
   - [x] 可以在休息点恢复生命
   - [x] 完成所有房间后冒险结束

4. **Boss 战斗** ✓
   - [x] Boss 有更高生命值
   - [x] Boss 有独特 AI 行为
   - [x] 击败 Boss 后冒险胜利

---

## 🧪 测试计划

### 单元测试
```bash
# 测试地图生成
swift test --filter MapGeneratorTests

# 测试路径连接
swift test --filter MapPathTests

# 测试 RunState
swift test --filter RunStateTests
```

### 集成测试
```bash
# 完整冒险流程
swift build && echo "1" | ./.build/debug/GameCLI

# 使用固定种子验证可复现
swift build && ./.build/debug/GameCLI --seed=12345
```

### 手动测试清单
- [ ] 启动游戏，选择"开始新战斗"
- [ ] 验证显示地图界面
- [ ] 完成第一场战斗
- [ ] 验证生命值保持
- [ ] 在分叉点选择路径
- [ ] 到达休息点，验证生命恢复
- [ ] 继续战斗直到 Boss
- [ ] 击败 Boss，验证胜利界面
- [ ] 使用相同种子，验证地图相同

---

## 🐛 已知问题和未来改进

### 已知限制
1. 地图只有 1 章（Act 1）
2. Boss 只有史莱姆 Boss
3. 没有其他房间类型（商店、事件、精英）
4. 没有遗物系统（P5）
5. 没有卡牌奖励系统（P3）

### 未来扩展（后续 P 阶段）
- P3: 战斗后奖励系统（卡牌、金币）
- P4: 存档系统（保存进度）
- P5: 遗物系统（被动效果）
- P6: 更多房间类型（商店、事件、精英、宝箱）

---

## 📝 实现注意事项

### 代码风格
- 遵循现有代码风格
- 使用 `Sendable` 协议保证线程安全
- 使用 `SeededRNG` 保证可复现性
- 所有游戏逻辑放在 `GameCore`，UI 放在 `GameCLI`

### 性能考虑
- 地图生成应该在 <100ms 内完成
- 不要在 `GameCore` 中使用 `print`
- 使用高效的算法生成路径

### 可测试性
- 所有核心逻辑应该是纯函数或可测试的
- 使用依赖注入（传入 RNG）
- 提供固定种子用于测试

---

## 📋 检查清单

### P2.1 线性地图 ✓
- [ ] `RoomType.swift` 创建
- [ ] `MapNode.swift` 创建
- [ ] `MapPath.swift` 创建
- [ ] `MapGenerator.generateLinearMap()` 实现
- [ ] 游戏能连续进行 5 场战斗

### P2.2 地图界面 ✓
- [ ] `MapScreen.swift` 创建
- [ ] 在战斗前显示地图
- [ ] 标记当前位置

### P2.3 连续战斗 ✓
- [ ] `RunState.swift` 创建
- [ ] `RunManager.swift` 创建
- [ ] 玩家生命值在战斗间保持
- [ ] 重构 `GameCLI.swift` 使用 `RunManager`

### P2.4 休息节点 ✓
- [ ] 地图包含休息节点
- [ ] `RestScreen.swift` 创建
- [ ] 休息恢复 30 点生命

### P2.5 分叉路径 ✓
- [ ] `MapNode` 添加 `column` 字段
- [ ] `generateBranchingMap()` 实现
- [ ] `getNextNodes()` 实现
- [ ] `MapScreen.showWithChoices()` 实现
- [ ] 玩家可以选择路径

### P2.6 程序生成 ✓
- [ ] `MapConfig` 创建
- [ ] `generateProceduralMap()` 完整实现
- [ ] `determineRoomType()` 实现
- [ ] `generateConnections()` 实现
- [ ] 地图随机生成 15 层

### P2.7 Boss 节点 ✓
- [ ] 添加 Boss 敌人类型
- [ ] 实现 Boss AI
- [ ] Boss 战斗界面特殊显示
- [ ] 击败 Boss 后胜利

---

## 📅 时间估算

| 阶段 | 预计时间 | 累计时间 |
|------|----------|----------|
| P2.1 | 20 分钟 | 20 分钟 |
| P2.2 | 30 分钟 | 50 分钟 |
| P2.3 | 20 分钟 | 1 小时 10 分钟 |
| P2.4 | 20 分钟 | 1 小时 30 分钟 |
| P2.5 | 45 分钟 | 2 小时 15 分钟 |
| P2.6 | 1.5 小时 | 3 小时 45 分钟 |
| P2.7 | 30 分钟 | 4 小时 15 分钟 |

**总计**：约 4-5 小时（包含测试和调试时间）

---

## ✅ 完成标志

当以下所有条件满足时，P2 视为完成：

1. ✅ 所有代码编译通过，无警告
2. ✅ 游戏启动后能生成完整地图
3. ✅ 玩家能选择路径并完成整个冒险
4. ✅ 生命值在战斗间正确保持
5. ✅ 休息点正确恢复生命
6. ✅ Boss 战斗正常工作
7. ✅ 使用固定种子可以复现相同地图
8. ✅ 所有手动测试项通过

---

**状态：✅ 已完成！** 🎉

**完成时间**: 2026-01-03

**实际耗时**: 约 4 小时

**实现总结**:
- 成功实现了完整的地图系统，从简单的线性地图到复杂的程序生成地图
- 实现了 15 层的程序化地图生成，包含战斗、休息和 Boss 房间
- 玩家可以在分叉路径中做出选择
- HP 在战斗间正确保持
- 添加了休息节点用于恢复生命
- 实现了 Boss 战斗，Boss 拥有更高的生命值和独特的 AI 行为
- 所有功能经过编译测试，运行正常

**后续工作** (P3-P7):
- P3: 奖励系统（战斗后获得卡牌和金币）
- P4: 存档系统（保存冒险进度）
- P5: 遗物系统（被动效果）
- P6: 多角色
- P7: AI 集成
