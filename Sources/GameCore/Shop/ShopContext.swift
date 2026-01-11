/// 商店生成上下文（P4 扩展）
public struct ShopContext: Sendable {
    public let seed: UInt64
    public let floor: Int
    public let currentRow: Int
    public let nodeId: String
    /// 已拥有的遗物 ID（用于过滤商店遗物）
    public let ownedRelicIds: [RelicID]
    
    public init(
        seed: UInt64,
        floor: Int,
        currentRow: Int,
        nodeId: String,
        ownedRelicIds: [RelicID] = []
    ) {
        self.seed = seed
        self.floor = floor
        self.currentRow = currentRow
        self.nodeId = nodeId
        self.ownedRelicIds = ownedRelicIds
    }
}
