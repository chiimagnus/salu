/// 地图生成器
/// 负责生成不同类型的地图
public struct MapGenerator {
    
    /// 地图配置
    public struct MapConfig: Sendable {
        public let floors: Int              // 总楼层数
        public let minColumnsPerFloor: Int  // 每层最少节点数
        public let maxColumnsPerFloor: Int  // 每层最多节点数
        public let bossFloor: Int           // Boss 楼层
        public let restFloorInterval: Int   // 休息点间隔
        
        public static let act1 = MapConfig(
            floors: 15,
            minColumnsPerFloor: 2,
            maxColumnsPerFloor: 4,
            bossFloor: 14,
            restFloorInterval: 6
        )
    }
    
    /// 生成简单的线性地图（5 个节点，包含 1 个休息）
    /// - Returns: 节点列表和路径列表
    public static func generateLinearMap() -> (nodes: [MapNode], paths: [MapPath]) {
        var nodes: [MapNode] = []
        var paths: [MapPath] = []
        
        // 楼层 0-1: 战斗
        nodes.append(MapNode(id: 0, floor: 0, column: 0, roomType: .battle))
        nodes.append(MapNode(id: 1, floor: 1, column: 0, roomType: .battle))
        
        // 楼层 2: 休息
        nodes.append(MapNode(id: 2, floor: 2, column: 0, roomType: .rest))
        
        // 楼层 3-4: 战斗
        nodes.append(MapNode(id: 3, floor: 3, column: 0, roomType: .battle))
        nodes.append(MapNode(id: 4, floor: 4, column: 0, roomType: .battle))
        
        // 连接所有节点
        for i in 0..<4 {
            paths.append(MapPath(from: i, to: i + 1))
        }
        
        return (nodes, paths)
    }
    
    /// 生成有分叉的地图
    /// - Returns: 节点列表和路径列表
    public static func generateBranchingMap() -> (nodes: [MapNode], paths: [MapPath]) {
        var nodes: [MapNode] = []
        var paths: [MapPath] = []
        var nodeId = 0
        
        // 楼层 0: 起始（1 个战斗）
        nodes.append(MapNode(id: nodeId, floor: 0, column: 1, roomType: .battle))
        nodeId += 1
        
        // 楼层 1: 分叉（2 个战斗选择）
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
        nodes.append(MapNode(id: nodeId, floor: 2, column: 1, roomType: .rest))
        let restId = nodeId
        nodeId += 1
        
        // 连接 1a, 1b → rest
        paths.append(MapPath(from: 1, to: restId))
        paths.append(MapPath(from: 2, to: restId))
        
        // 楼层 3: 再次分叉（2 个战斗选择）
        let node3a = MapNode(id: nodeId, floor: 3, column: 0, roomType: .battle)
        nodes.append(node3a)
        nodeId += 1
        
        let node3b = MapNode(id: nodeId, floor: 3, column: 2, roomType: .battle)
        nodes.append(node3b)
        nodeId += 1
        
        // 连接 rest → 3a, 3b
        paths.append(MapPath(from: restId, to: 4))
        paths.append(MapPath(from: restId, to: 5))
        
        // 楼层 4: 最终战斗
        nodes.append(MapNode(id: nodeId, floor: 4, column: 1, roomType: .battle))
        let finalId = nodeId
        
        // 连接 3a, 3b → final
        paths.append(MapPath(from: 4, to: finalId))
        paths.append(MapPath(from: 5, to: finalId))
        
        return (nodes, paths)
    }
    
    /// 生成程序化地图（杀戮尖塔风格）
    /// - Parameters:
    ///   - config: 地图配置
    ///   - seed: 随机数种子
    /// - Returns: 节点列表和路径列表
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
                    upperBound: config.maxColumnsPerFloor + 1
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
        var connectedCurrent = Set<Int>()
        var connectedPrevious = Set<Int>()
        
        // 确保每个当前节点至少有一条入路
        for currentNode in currentNodes {
            // 随机选择 1-2 个父节点连接
            let connectionCount = rng.nextInt(upperBound: 100) < 70 ? 1 : 2
            let shuffledPrevious = rng.shuffled(previousNodes)
            
            for i in 0..<min(connectionCount, shuffledPrevious.count) {
                paths.append(MapPath(from: shuffledPrevious[i], to: currentNode))
                connectedPrevious.insert(shuffledPrevious[i])
            }
            connectedCurrent.insert(currentNode)
        }
        
        // 确保每个上层节点至少有一个出口
        for previousNode in previousNodes {
            if !connectedPrevious.contains(previousNode) {
                let randomCurrent = currentNodes[rng.nextInt(upperBound: currentNodes.count)]
                paths.append(MapPath(from: previousNode, to: randomCurrent))
            }
        }
        
        return paths
    }
}
