/// 地图路径
/// 表示两个节点之间的连接
public struct MapPath: Sendable {
    public let fromNodeId: Int  // 起始节点
    public let toNodeId: Int    // 目标节点
    
    public init(from: Int, to: Int) {
        self.fromNodeId = from
        self.toNodeId = to
    }
}
