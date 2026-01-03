/// 地图生成器
/// 负责生成不同类型的地图
public struct MapGenerator {
    
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
}
