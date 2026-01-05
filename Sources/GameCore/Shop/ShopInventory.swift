/// 商店卡牌报价
public struct ShopCardOffer: Sendable, Equatable {
    public let cardId: CardID
    public let price: Int
    
    public init(cardId: CardID, price: Int) {
        self.cardId = cardId
        self.price = price
    }
}

/// 商店库存
public struct ShopInventory: Sendable, Equatable {
    public let cardOffers: [ShopCardOffer]
    public let removeCardPrice: Int
    
    public init(cardOffers: [ShopCardOffer], removeCardPrice: Int = ShopPricing.removeCardPrice) {
        self.cardOffers = cardOffers
        self.removeCardPrice = removeCardPrice
    }
    
    /// 统一条目列表（卡牌 + 删牌服务）
    public var items: [ShopItem] {
        var result = cardOffers.map { ShopItem(kind: .card($0)) }
        result.append(ShopItem(kind: .removeCard(price: removeCardPrice)))
        return result
    }
    
    /// 生成商店库存（可复现）
    public static func generate(context: ShopContext) -> ShopInventory {
        var rng = SeededRNG(seed: deriveShopSeed(context: context))
        return generate(context: context, rng: &rng)
    }
    
    /// 生成商店库存（使用外部 RNG）
    public static func generate(context: ShopContext, rng: inout SeededRNG) -> ShopInventory {
        let pool = CardPool.rewardableCardIds()
        let offerCount = min(ShopInventory.defaultCardOfferCount, pool.count)
        
        let choices = Array(rng.shuffled(pool).prefix(offerCount))
        let offers = choices.map { cardId in
            ShopCardOffer(cardId: cardId, price: ShopPricing.cardPrice(for: cardId))
        }
        
        return ShopInventory(cardOffers: offers, removeCardPrice: ShopPricing.removeCardPrice)
    }
    
    private static func deriveShopSeed(context: ShopContext) -> UInt64 {
        var s = context.seed
        s ^= UInt64(context.floor) &* 0x9E3779B97F4A7C15
        s ^= UInt64(context.currentRow) &* 0xBF58476D1CE4E5B9
        s ^= fnv1a64(context.nodeId)
        s ^= 0x5A0F_5EED_0000_0000
        return s
    }
    
    private static func fnv1a64(_ string: String) -> UInt64 {
        let bytes = Array(string.utf8)
        var hash: UInt64 = 0xcbf29ce484222325
        for b in bytes {
            hash ^= UInt64(b)
            hash &*= 0x100000001b3
        }
        return hash
    }
    
    private static let defaultCardOfferCount = 3
}
