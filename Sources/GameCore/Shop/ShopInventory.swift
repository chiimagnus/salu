// MARK: - Shop Inventory

/// 商店库存（P4 扩展：支持卡牌、遗物、消耗品）
public struct ShopInventory: Sendable, Equatable {
    /// 卡牌报价（5 张）
    public let cardOffers: [ShopCardOffer]
    /// 遗物报价（3 个）
    public let relicOffers: [ShopRelicOffer]
    /// 消耗品报价（3 个）
    public let consumableOffers: [ShopConsumableOffer]
    /// 删牌服务价格
    public let removeCardPrice: Int
    
    public init(
        cardOffers: [ShopCardOffer],
        relicOffers: [ShopRelicOffer] = [],
        consumableOffers: [ShopConsumableOffer] = [],
        removeCardPrice: Int = ShopPricing.removeCardPrice
    ) {
        self.cardOffers = cardOffers
        self.relicOffers = relicOffers
        self.consumableOffers = consumableOffers
        self.removeCardPrice = removeCardPrice
    }
    
    /// 统一条目列表（卡牌 + 遗物 + 消耗品 + 删牌服务）
    public var items: [ShopItem] {
        var result: [ShopItem] = []
        result.append(contentsOf: cardOffers.map { ShopItem(kind: .card($0)) })
        result.append(contentsOf: relicOffers.map { ShopItem(kind: .relic($0)) })
        result.append(contentsOf: consumableOffers.map { ShopItem(kind: .consumable($0)) })
        result.append(ShopItem(kind: .removeCard(price: removeCardPrice)))
        return result
    }
    
    // MARK: - Generation
    
    /// 生成商店库存（可复现）
    public static func generate(context: ShopContext) -> ShopInventory {
        var rng = SeededRNG(seed: deriveShopSeed(context: context))
        return generate(context: context, rng: &rng)
    }
    
    /// 生成商店库存（使用外部 RNG）
    public static func generate(context: ShopContext, rng: inout SeededRNG) -> ShopInventory {
        // 卡牌：5 张
        let cardPool = CardPool.rewardableCardIds()
        let cardOfferCount = min(defaultCardOfferCount, cardPool.count)
        let cardChoices = Array(rng.shuffled(cardPool).prefix(cardOfferCount))
        let cardOffers = cardChoices.map { cardId in
            ShopCardOffer(cardId: cardId, price: ShopPricing.cardPrice(for: cardId))
        }
        
        // 遗物：3 个（排除已拥有的遗物）
        let relicPool = RelicPool.availableRelicIds(excluding: context.ownedRelicIds)
        let relicOfferCount = min(defaultRelicOfferCount, relicPool.count)
        let relicChoices = Array(rng.shuffled(relicPool).prefix(relicOfferCount))
        let relicOffers = relicChoices.map { relicId in
            ShopRelicOffer(relicId: relicId, price: ShopPricing.relicPrice(for: relicId))
        }
        
        // 消耗品：3 个
        let consumablePool = ConsumableRegistry.shopConsumableIds
        let consumableOfferCount = min(defaultConsumableOfferCount, consumablePool.count)
        let consumableChoices = Array(rng.shuffled(consumablePool).prefix(consumableOfferCount))
        let consumableOffers = consumableChoices.map { consumableId in
            ShopConsumableOffer(consumableId: consumableId, price: ShopPricing.consumablePrice(for: consumableId))
        }
        
        return ShopInventory(
            cardOffers: cardOffers,
            relicOffers: relicOffers,
            consumableOffers: consumableOffers,
            removeCardPrice: ShopPricing.removeCardPrice
        )
    }
    
    // MARK: - Private Helpers
    
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
    
    // MARK: - Constants
    
    private static let defaultCardOfferCount = 5        // 原来是 3，扩展为 5
    private static let defaultRelicOfferCount = 3       // P4 新增
    private static let defaultConsumableOfferCount = 3  // P4 新增
}
