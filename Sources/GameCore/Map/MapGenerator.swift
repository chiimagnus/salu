/// 地图生成器
/// 负责程序化生成分支地图
public enum MapGenerator {
    
    // MARK: - 地图生成配置
    
    /// 默认地图层数（包含起点和Boss）
    #if os(visionOS)
    public static let defaultRowCount = 3
    #else
    public static let defaultRowCount = 15
    #endif
    
    /// 每层最少节点数
    public static let minNodesPerRow = 2
    
    /// 每层最多节点数
    public static let maxNodesPerRow = 4
    
    // MARK: - 公共方法
    
    /// 生成分支地图
    /// - Parameters:
    ///   - seed: 随机种子
    ///   - rows: 层数（默认 `defaultRowCount`）
    /// - Returns: 地图节点数组
    public static func generateBranching(seed: UInt64, rows: Int = defaultRowCount) -> [MapNode] {
        var rng = SeededRNG(seed: seed)
        var nodes: [MapNode] = []
        
        // 记录每层的节点数，用于生成连接
        var rowNodeCounts: [Int] = []
        
        // 生成每层节点
        for row in 0..<rows {
            let rowNodes = generateRow(row: row, totalRows: rows, rng: &rng)
            rowNodeCounts.append(rowNodes.count)
            nodes.append(contentsOf: rowNodes)
        }

        // P2：保证至少有 1 个商店节点（避免极端种子导致整张图没有商店）
        ensureAtLeastOneShop(&nodes, totalRows: rows, rng: &rng)
        
        // 生成节点间的连接
        connectNodes(&nodes, rowNodeCounts: rowNodeCounts, rng: &rng)
        
        // 设置起点可进入
        if let startIndex = nodes.nodeIndex(withId: "0_0") {
            nodes[startIndex].isAccessible = true
        }
        
        return nodes
    }
    
    // MARK: - 私有方法
    
    /// 生成指定层的节点
    private static func generateRow(row: Int, totalRows: Int, rng: inout SeededRNG) -> [MapNode] {
        var rowNodes: [MapNode] = []
        
        // 确定节点数量
        let nodeCount: Int
        if row == 0 {
            // 起点：1个节点
            nodeCount = 1
        } else if row == totalRows - 1 {
            // Boss层：1个节点
            nodeCount = 1
        } else {
            // 中间层：2-4个节点
            nodeCount = minNodesPerRow + rng.nextInt(upperBound: maxNodesPerRow - minNodesPerRow + 1)
        }
        
        // 生成节点
        for col in 0..<nodeCount {
            let roomType = decideRoomType(row: row, totalRows: totalRows, rng: &rng)
            let node = MapNode(
                id: "\(row)_\(col)",
                row: row,
                column: col,
                roomType: roomType
            )
            rowNodes.append(node)
        }

        // P3：休息点行（第 6/12 层）至少保证有一个休息节点
        if (row == 6 || row == 12),
           !rowNodes.isEmpty,
           !rowNodes.contains(where: { $0.roomType == .rest }) {
            let pick = rng.nextInt(upperBound: rowNodes.count)
            let old = rowNodes[pick]
            rowNodes[pick] = MapNode(
                id: old.id,
                row: old.row,
                column: old.column,
                roomType: .rest,
                connections: old.connections,
                isCompleted: old.isCompleted,
                isAccessible: old.isAccessible
            )
        }
        
        return rowNodes
    }
    
    /// 决定房间类型
    private static func decideRoomType(row: Int, totalRows: Int, rng: inout SeededRNG) -> RoomType {
        if row == 0 {
            return .start
        }
        
        if row == totalRows - 1 {
            return .boss
        }
        
        // 休息点分布：第 6 层和第 12 层固定有休息点
        // （或者按比例：约每隔 5 层有休息机会）
        if row == 6 || row == 12 {
            // 50% 概率是休息点
            if rng.nextInt(upperBound: 2) == 0 {
                return .rest
            }
        }
        
        // 精英分布：第 8-10 层可能有精英
        if row >= 8 && row <= 10 {
            // 30% 概率是精英
            if rng.nextInt(upperBound: 10) < 3 {
                return .elite
            }
        }

        // P5：事件分布：中段层数有机会出现事件（避免影响前两层的战斗/测试稳定性）
        if row >= 3 && row <= 12 {
            // 12% 概率是事件
            if rng.nextInt(upperBound: 100) < 12 {
                return .event
            }
        }
        
        // 商店分布：中段层数有机会出现商店
        if row >= 3 && row <= 12 {
            // 15% 概率是商店
            if rng.nextInt(upperBound: 100) < 15 {
                return .shop
            }
        }
        
        // 默认是普通战斗
        return .battle
    }
    
    /// 生成节点间的连接
    private static func connectNodes(_ nodes: inout [MapNode], rowNodeCounts: [Int], rng: inout SeededRNG) {
        let totalRows = rowNodeCounts.count
        
        for row in 0..<(totalRows - 1) {
            let currentRowNodes = nodes.nodes(atRow: row)
            let nextRowNodes = nodes.nodes(atRow: row + 1)
            
            guard !nextRowNodes.isEmpty else { continue }
            
            // 为当前层的每个节点分配连接
            for currentNode in currentRowNodes {
                guard let currentIndex = nodes.nodeIndex(withId: currentNode.id) else { continue }
                
                // 每个节点连接 1-2 个下一层节点
                let connectionCount = 1 + rng.nextInt(upperBound: 2)
                var targetIndices: [Int] = []
                
                // 优先连接相近列的节点
                let baseTargetCol = min(currentNode.column, nextRowNodes.count - 1)
                targetIndices.append(baseTargetCol)
                
                // 如果需要第二个连接，选择相邻的节点
                if connectionCount > 1 && nextRowNodes.count > 1 {
                    let secondTarget: Int
                    if baseTargetCol > 0 && rng.nextInt(upperBound: 2) == 0 {
                        secondTarget = baseTargetCol - 1
                    } else if baseTargetCol < nextRowNodes.count - 1 {
                        secondTarget = baseTargetCol + 1
                    } else {
                        secondTarget = baseTargetCol - 1
                    }
                    if !targetIndices.contains(secondTarget) && secondTarget >= 0 {
                        targetIndices.append(secondTarget)
                    }
                }
                
                // 设置连接
                var connections: [String] = []
                for targetCol in targetIndices {
                    if targetCol >= 0 && targetCol < nextRowNodes.count {
                        connections.append(nextRowNodes[targetCol].id)
                    }
                }
                
                nodes[currentIndex].connections = connections
            }
        }
        
        // 确保每个非起点节点至少有一个入口
        ensureAllNodesReachable(&nodes, rowNodeCounts: rowNodeCounts, rng: &rng)
    }
    
    /// 确保所有节点都可到达
    private static func ensureAllNodesReachable(_ nodes: inout [MapNode], rowNodeCounts: [Int], rng: inout SeededRNG) {
        let totalRows = rowNodeCounts.count
        
        for row in 1..<totalRows {
            let currentRowNodes = nodes.nodes(atRow: row)
            let prevRowNodes = nodes.nodes(atRow: row - 1)
            
            for currentNode in currentRowNodes {
                // 检查是否有入口
                let hasIncoming = prevRowNodes.contains { $0.connections.contains(currentNode.id) }
                
                if !hasIncoming {
                    // 随机选择一个上层节点连接到当前节点
                    let randomPrevIndex = rng.nextInt(upperBound: prevRowNodes.count)
                    let prevNodeId = prevRowNodes[randomPrevIndex].id
                    
                    if let prevIndex = nodes.nodeIndex(withId: prevNodeId) {
                        nodes[prevIndex].connections.append(currentNode.id)
                    }
                }
            }
        }
    }

    // MARK: - Post Processing
    
    private static func ensureAtLeastOneShop(_ nodes: inout [MapNode], totalRows: Int, rng: inout SeededRNG) {
        guard !nodes.contains(where: { $0.roomType == .shop }) else { return }
        
        // 优先在中段 battle 节点中挑一个变成商店，避免抢走精英/休息/Boss
        let preferredRowsUpperBound = max(1, totalRows - 4) // 排除最后 3 行（通常包含休息/Boss）
        let preferredCandidates = nodes.indices.filter { idx in
            let node = nodes[idx]
            return node.roomType == .battle && node.row >= 3 && node.row <= preferredRowsUpperBound
        }
        
        let candidates = preferredCandidates.isEmpty
            ? nodes.indices.filter { idx in
                let node = nodes[idx]
                return node.roomType == .battle && node.row > 0 && node.row < totalRows - 1
            }
            : preferredCandidates
        
        guard !candidates.isEmpty else { return }
        let chosenIndex = candidates[rng.nextInt(upperBound: candidates.count)]
        let old = nodes[chosenIndex]
        nodes[chosenIndex] = MapNode(
            id: old.id,
            row: old.row,
            column: old.column,
            roomType: .shop,
            connections: old.connections,
            isCompleted: old.isCompleted,
            isAccessible: old.isAccessible
        )
    }
}
