/// 商店定价规则（P4 扩展）
public enum ShopPricing {
    // MARK: - 删牌服务
    
    /// 删牌服务价格
    public static let removeCardPrice = 75
    
    // MARK: - 卡牌定价
    
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
    
    // MARK: - 遗物定价（P4 新增）
    
    /// 购买遗物价格
    public static func relicPrice(for relicId: RelicID) -> Int {
        let def = RelicRegistry.require(relicId)
        return relicPrice(for: def.rarity)
    }
    
    public static func relicPrice(for rarity: RelicRarity) -> Int {
        switch rarity {
        case .starter:
            return 50   // 起始遗物不应出现在商店
        case .common:
            return 100
        case .uncommon:
            return 150
        case .rare:
            return 250
        case .boss:
            return 300  // Boss 遗物不应出现在商店
        case .event:
            return 100  // 事件遗物不应出现在商店
        }
    }
    
    // MARK: - 消耗品定价（P4 新增）
    
    /// 购买消耗品价格
    public static func consumablePrice(for consumableId: ConsumableID) -> Int {
        let def = ConsumableRegistry.require(consumableId)
        return consumablePrice(for: def.rarity)
    }
    
    public static func consumablePrice(for rarity: ConsumableRarity) -> Int {
        switch rarity {
        case .common:
            return 35
        case .uncommon:
            return 60
        case .rare:
            return 100
        }
    }
}
