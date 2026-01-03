/// 卡牌实例（运行时）
/// 仅保存 instanceId  cardId（定义 ID）；所有静态属性都通过 CardRegistry 查定义。
public struct Card: Identifiable, Sendable, Equatable {
    public let id: String
    public let cardId: CardID
    
    public init(id: String, cardId: CardID) {
        self.id = id
        self.cardId = cardId
    }
    
    /// 便捷：获取定义（找不到会直接失败，符合破坏性策略）
    public var definition: any CardDefinition.Type {
        CardRegistry.require(cardId)
    }
    
    public var cost: Int { definition.cost }
    public var name: String { definition.name }
    public var rulesText: String { definition.rulesText }
    public var type: CardType { definition.type }
}
