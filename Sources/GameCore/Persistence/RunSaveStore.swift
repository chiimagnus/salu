import Foundation

/// Run 存档存储协议
/// 定义冒险存档的持久化接口，具体实现将在 P7 提供
/// P6 阶段只定义接口，为未来的存档系统预留扩展点
public protocol RunSaveStore: Sendable {
    /// 加载冒险存档
    /// - Throws: 加载失败时抛出错误
    /// - Returns: 存档快照，如果不存在则返回 nil
    func load() throws -> RunSnapshot?
    
    /// 保存冒险存档
    /// - Parameter snapshot: 要保存的冒险快照
    /// - Throws: 保存失败时抛出错误
    func save(_ snapshot: RunSnapshot) throws
    
    /// 清除冒险存档
    /// - Throws: 清除失败时抛出错误
    func clear() throws
}

/// 冒险存档快照
/// 包含冒险进度的完整可序列化状态
public struct RunSnapshot: Codable, Sendable {
    /// 存档版本号
    public let version: Int
    
    /// 随机种子
    public let seed: UInt64
    
    /// 当前楼层
    public let floor: Int
    
    /// 地图节点数据（简化序列化）
    public struct NodeData: Codable, Sendable {
        public let id: String
        public let row: Int
        public let column: Int
        public let roomType: String  // RoomType rawValue
        public let connections: [String]
        public let isCompleted: Bool
        public let isAccessible: Bool
        
        public init(id: String, row: Int, column: Int, roomType: String, 
                   connections: [String], isCompleted: Bool, isAccessible: Bool) {
            self.id = id
            self.row = row
            self.column = column
            self.roomType = roomType
            self.connections = connections
            self.isCompleted = isCompleted
            self.isAccessible = isAccessible
        }
    }
    
    /// 地图节点列表
    public let mapNodes: [NodeData]
    
    /// 当前所在节点 ID
    public let currentNodeId: String?
    
    /// 玩家状态数据
    public struct PlayerData: Codable, Sendable {
        public let maxHP: Int
        public let currentHP: Int
        public let statuses: [String: Int]  // StatusID -> stacks
        
        public init(maxHP: Int, currentHP: Int, statuses: [String: Int]) {
            self.maxHP = maxHP
            self.currentHP = currentHP
            self.statuses = statuses
        }
    }
    
    /// 玩家状态
    public let player: PlayerData
    
    /// 卡牌数据（简化）
    public struct CardData: Codable, Sendable {
        public let id: String
        public let cardId: String  // CardID
        
        public init(id: String, cardId: String) {
            self.id = id
            self.cardId = cardId
        }
    }
    
    /// 牌组
    public let deck: [CardData]
    
    /// 遗物 ID 列表
    public let relicIds: [String]  // RelicID array
    
    /// 是否已结束
    public let isOver: Bool
    
    /// 是否胜利
    public let won: Bool
    
    public init(version: Int, seed: UInt64, floor: Int, mapNodes: [NodeData], 
                currentNodeId: String?, player: PlayerData, deck: [CardData], 
                relicIds: [String], isOver: Bool, won: Bool) {
        self.version = version
        self.seed = seed
        self.floor = floor
        self.mapNodes = mapNodes
        self.currentNodeId = currentNodeId
        self.player = player
        self.deck = deck
        self.relicIds = relicIds
        self.isOver = isOver
        self.won = won
    }
}
