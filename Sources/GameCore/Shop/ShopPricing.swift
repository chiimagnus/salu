/// 商店定价规则
public enum ShopPricing {
    /// 删牌服务价格
    public static let removeCardPrice = 75
    
    /// 购买卡牌价格
    public static func cardPrice(for cardId: CardID) -> Int {
        let def = CardRegistry.require(cardId)
        return cardPrice(for: def.rarity)
    }
    
    public static func cardPrice(for rarity: CardRarity) -> Int {
        switch rarity {
        case .starter:
            return 30
        case .common:
            return 45
        case .uncommon:
            return 75
        case .rare:
            return 150
        }
    }
}
