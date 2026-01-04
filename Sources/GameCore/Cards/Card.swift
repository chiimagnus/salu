/// 卡牌实例
/// 表示一张具体的卡牌实例，只引用卡牌定义
public struct Card: Identifiable, Sendable, Equatable {
    /// 实例 ID（用于区分同类型的多张卡）
    public let id: String
    
    /// 卡牌定义 ID（引用卡牌定义）
    public let cardId: CardID
    
    public init(id: String, cardId: CardID) {
        self.id = id
        self.cardId = cardId
    }
}

