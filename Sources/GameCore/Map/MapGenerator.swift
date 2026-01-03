/// 地图生成器
/// 负责生成不同类型的地图
public struct MapGenerator {
    
    /// 生成简单的线性地图（5 个战斗节点）
    /// - Returns: 节点列表和路径列表
    public static func generateLinearMap() -> (nodes: [MapNode], paths: [MapPath]) {
        var nodes: [MapNode] = []
        var paths: [MapPath] = []
        
        // 创建 5 个战斗节点
        for i in 0..<5 {
            let node = MapNode(id: i, floor: i, column: 0, roomType: .battle)
            nodes.append(node)
            
            // 连接到下一个节点
            if i < 4 {
                paths.append(MapPath(from: i, to: i + 1))
            }
        }
        
        return (nodes, paths)
    }
}
