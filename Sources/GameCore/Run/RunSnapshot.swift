/// 冒险存档快照
/// 包含冒险进度的完整可序列化状态（Run 维度）
public struct RunSnapshot: Codable, Sendable {
    /// 存档版本号（由 `RunSaveVersion` 管理）
    public let version: Int
    
    /// 随机种子
    public let seed: UInt64
    
    /// 当前楼层
    public let floor: Int
    
    // MARK: - Map
    
    /// 地图节点数据（简化序列化）
    public struct NodeData: Codable, Sendable {
        public let id: String
        public let row: Int
        public let column: Int
        public let roomType: String  // RoomType.rawValue
        public let connections: [String]
        public let isCompleted: Bool
        public let isAccessible: Bool
        
        public init(
            id: String,
            row: Int,
            column: Int,
            roomType: String,
            connections: [String],
            isCompleted: Bool,
            isAccessible: Bool
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
    
    /// 地图节点列表
    public let mapNodes: [NodeData]
    
    /// 当前所在节点 ID
    public let currentNodeId: String?
    
    // MARK: - Player
    
    /// 玩家状态数据
    public struct PlayerData: Codable, Sendable {
        public let maxHP: Int
        public let currentHP: Int
        public let statuses: [String: Int]  // StatusID.rawValue -> stacks
        
        public init(maxHP: Int, currentHP: Int, statuses: [String: Int]) {
            self.maxHP = maxHP
            self.currentHP = currentHP
            self.statuses = statuses
        }
    }
    
    /// 玩家状态
    public let player: PlayerData
    
    // MARK: - Deck
    
    /// 卡牌数据（简化）
    public struct CardData: Codable, Sendable {
        public let id: String
        public let cardId: String  // CardID.rawValue
        
        public init(id: String, cardId: String) {
            self.id = id
            self.cardId = cardId
        }
    }
    
    /// 牌组
    public let deck: [CardData]
    
    // MARK: - Relics
    
    /// 遗物 ID 列表
    public let relicIds: [String]  // RelicID.rawValue array
    
    // MARK: - Run End
    
    /// 是否已结束
    public let isOver: Bool
    
    /// 是否胜利
    public let won: Bool
    
    public init(
        version: Int,
        seed: UInt64,
        floor: Int,
        mapNodes: [NodeData],
        currentNodeId: String?,
        player: PlayerData,
        deck: [CardData],
        relicIds: [String],
        isOver: Bool,
        won: Bool
    ) {
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


