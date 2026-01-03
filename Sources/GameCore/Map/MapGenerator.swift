/// 地图生成器
/// 负责生成不同类型的地图
public struct MapGenerator {
    
    /// 生成简单的线性地图（5 个战斗节点）
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
}
