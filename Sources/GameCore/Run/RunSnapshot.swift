/// 冒险存档快照
/// 包含冒险进度的完整可序列化状态（Run 维度）
public struct RunSnapshot: Codable, Sendable {
    /// 存档版本号（由 `RunSaveVersion` 管理）
    public let version: Int
    
    /// 随机种子
    public let seed: UInt64
    
    /// 当前楼层
    public let floor: Int
    
    /// 最大楼层（Act 数）
    public let maxFloor: Int
    
    /// 当前金币
    public let gold: Int
    
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
        maxFloor: Int,
        gold: Int,
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
        self.maxFloor = maxFloor
        self.gold = gold
        self.mapNodes = mapNodes
        self.currentNodeId = currentNodeId
        self.player = player
        self.deck = deck
        self.relicIds = relicIds
        self.isOver = isOver
        self.won = won
    }
}

// MARK: - Codable

extension RunSnapshot {
    private enum CodingKeys: String, CodingKey {
        case version
        case seed
        case floor
        case maxFloor
        case gold
        case mapNodes
        case currentNodeId
        case player
        case deck
        case relicIds
        case isOver
        case won
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(Int.self, forKey: .version)
        seed = try container.decode(UInt64.self, forKey: .seed)
        floor = try container.decode(Int.self, forKey: .floor)
        maxFloor = try container.decode(Int.self, forKey: .maxFloor)
        gold = try container.decode(Int.self, forKey: .gold)
        mapNodes = try container.decode([NodeData].self, forKey: .mapNodes)
        currentNodeId = try container.decodeIfPresent(String.self, forKey: .currentNodeId)
        player = try container.decode(PlayerData.self, forKey: .player)
        deck = try container.decode([CardData].self, forKey: .deck)
        relicIds = try container.decode([String].self, forKey: .relicIds)
        isOver = try container.decode(Bool.self, forKey: .isOver)
        won = try container.decode(Bool.self, forKey: .won)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(seed, forKey: .seed)
        try container.encode(floor, forKey: .floor)
        try container.encode(maxFloor, forKey: .maxFloor)
        try container.encode(gold, forKey: .gold)
        try container.encode(mapNodes, forKey: .mapNodes)
        try container.encode(currentNodeId, forKey: .currentNodeId)
        try container.encode(player, forKey: .player)
        try container.encode(deck, forKey: .deck)
        try container.encode(relicIds, forKey: .relicIds)
        try container.encode(isOver, forKey: .isOver)
        try container.encode(won, forKey: .won)
    }
}
