/// 事件生成上下文（P5）
///
/// 用于在不引入 I/O 的情况下，让事件生成与结算保持可复现。
public struct EventContext: Sendable, Equatable {
    public let seed: UInt64
    public let floor: Int
    public let currentRow: Int
    public let nodeId: String
    
    // 当前 Run 状态快照（事件决策可用）
    public let playerMaxHP: Int
    public let playerCurrentHP: Int
    public let gold: Int
    public let deck: [Card]
    public let relicIds: [RelicID]
    
    public init(
        seed: UInt64,
        floor: Int,
        currentRow: Int,
        nodeId: String,
        playerMaxHP: Int,
        playerCurrentHP: Int,
        gold: Int,
        deck: [Card],
        relicIds: [RelicID]
    ) {
        self.seed = seed
        self.floor = floor
        self.currentRow = currentRow
        self.nodeId = nodeId
        self.playerMaxHP = playerMaxHP
        self.playerCurrentHP = playerCurrentHP
        self.gold = gold
        self.deck = deck
        self.relicIds = relicIds
    }
}


