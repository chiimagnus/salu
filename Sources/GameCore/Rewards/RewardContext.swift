/// 奖励上下文
/// 用于生成可复现的奖励结果（P1：战斗后卡牌奖励）
public struct RewardContext: Sendable, Equatable {
    public let seed: UInt64
    public let floor: Int
    public let currentRow: Int
    public let nodeId: String
    public let roomType: RoomType
    
    public init(seed: UInt64, floor: Int, currentRow: Int, nodeId: String, roomType: RoomType) {
        self.seed = seed
        self.floor = floor
        self.currentRow = currentRow
        self.nodeId = nodeId
        self.roomType = roomType
    }
}


