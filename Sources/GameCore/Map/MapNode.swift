/// 地图节点
/// 表示地图上的一个位置，包含房间类型和连接信息
public struct MapNode: Identifiable, Sendable, Equatable {
    public let id: String
    public let row: Int             // 层数（0=起点, 最后一层=Boss）
    public let column: Int          // 列位置（用于显示）
    public let roomType: RoomType   // 房间类型
    
    /// 连接的下一层节点 ID 列表
    public var connections: [String]
    
    /// 是否已完成（玩家已通过）
    public var isCompleted: Bool
    
    /// 是否可进入（当前可选择的节点）
    public var isAccessible: Bool
    
    public init(
        id: String,
        row: Int,
        column: Int,
        roomType: RoomType,
        connections: [String] = [],
        isCompleted: Bool = false,
        isAccessible: Bool = false
    ) {
        self.id = id
        self.row = row
        self.column = column
        self.roomType = roomType
        self.connections = connections
        self.isCompleted = isCompleted
        self.isAccessible = isAccessible
    }
}

// MARK: - MapNode 集合操作扩展

extension Array where Element == MapNode {
    
    /// 查找指定 ID 的节点
    public func node(withId id: String) -> MapNode? {
        first { $0.id == id }
    }
    
    /// 查找指定 ID 节点的索引
    public func nodeIndex(withId id: String) -> Int? {
        firstIndex { $0.id == id }
    }
    
    /// 获取指定层的所有节点
    public func nodes(atRow row: Int) -> [MapNode] {
        filter { $0.row == row }
    }
    
    /// 获取所有可进入的节点
    public var accessibleNodes: [MapNode] {
        filter { $0.isAccessible }
    }
    
    /// 获取最大层数
    public var maxRow: Int {
        map { $0.row }.max() ?? 0
    }
}

