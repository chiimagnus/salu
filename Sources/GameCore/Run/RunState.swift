import Foundation

/// 游戏会话状态
/// 包含整个冒险的状态信息
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
        
        // 初始化分叉地图
        let map = MapGenerator.generateBranchingMap()
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
    
    /// 获取当前节点
    public var currentNode: MapNode? {
        nodes.first { $0.id == currentNodeId }
    }
    
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
            nodes[nextIndex].isAccessible = true
            currentNodeId = nodeId
            currentFloor = nodes[nextIndex].floor
        }
    }
    
    /// 移动到下一个节点（自动选择，用于线性路径）
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
            nodes[nextIndex].isAccessible = true
            currentNodeId = nextNodeId
            currentFloor = nodes[nextIndex].floor
        } else {
            // 没有更多节点，冒险结束
            isRunOver = true
            won = true
        }
    }
}
