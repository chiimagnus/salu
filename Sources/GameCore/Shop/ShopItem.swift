// MARK: - Shop Item Types

/// 商店卡牌报价
public struct ShopCardOffer: Sendable, Equatable {
    public let cardId: CardID
    public let price: Int
    
    public init(cardId: CardID, price: Int) {
        self.cardId = cardId
        self.price = price
    }
}

/// 商店遗物报价（P4 新增）
public struct ShopRelicOffer: Sendable, Equatable {
    public let relicId: RelicID
    public let price: Int
    
    public init(relicId: RelicID, price: Int) {
        self.relicId = relicId
        self.price = price
    }
}

/// 商店消耗性卡牌报价（P4R，原“消耗品”）
public struct ShopConsumableOffer: Sendable, Equatable {
    /// 消耗性卡牌 ID（`CardType.consumable`）
    public let cardId: CardID
    public let price: Int
    
    public init(cardId: CardID, price: Int) {
        self.cardId = cardId
        self.price = price
    }
}

/// 商店条目
public struct ShopItem: Sendable, Equatable {
    public enum Kind: Sendable, Equatable {
        case card(ShopCardOffer)
        case relic(ShopRelicOffer)           // P4: 遗物
        case consumable(ShopConsumableOffer) // P4R: 消耗性卡牌（原“消耗品”）
        case removeCard(price: Int)
    }
    
    public let kind: Kind
    
    public init(kind: Kind) {
        self.kind = kind
    }
    
    /// 获取条目价格
    public var price: Int {
        switch kind {
        case .card(let offer):
            return offer.price
        case .relic(let offer):
            return offer.price
        case .consumable(let offer):
            return offer.price
        case .removeCard(let price):
            return price
        }
    }
    
    /// 获取条目显示名称
    public func displayName(language: GameLanguage) -> String {
        switch kind {
        case .card(let offer):
            return CardRegistry.require(offer.cardId).name.resolved(for: language)
        case .relic(let offer):
            return RelicRegistry.require(offer.relicId).name.resolved(for: language)
        case .consumable(let offer):
            return CardRegistry.require(offer.cardId).name.resolved(for: language)
        case .removeCard:
            switch language {
            case .zhHans:
                return "删除卡牌"
            case .en:
                return "Remove Card"
            }
        }
    }
    
    /// 获取条目图标
    public var icon: String {
        switch kind {
        case .card:
            return "🃏"
        case .relic(let offer):
            return RelicRegistry.require(offer.relicId).icon
        case .consumable(let offer):
            _ = offer
            return "🧪"
        case .removeCard:
            return "🗑️"
        }
    }
}
