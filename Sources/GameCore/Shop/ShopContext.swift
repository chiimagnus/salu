/// 商店生成上下文
public struct ShopContext: Sendable {
    public let seed: UInt64
    public let floor: Int
    public let currentRow: Int
    public let nodeId: String
    
    public init(seed: UInt64, floor: Int, currentRow: Int, nodeId: String) {
        self.seed = seed
        self.floor = floor
        self.currentRow = currentRow
        self.nodeId = nodeId
    }
}
