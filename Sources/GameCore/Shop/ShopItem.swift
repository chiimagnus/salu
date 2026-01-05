/// 商店条目
public struct ShopItem: Sendable, Equatable {
    public enum Kind: Sendable, Equatable {
        case card(ShopCardOffer)
        case removeCard(price: Int)
    }
    
    public let kind: Kind
    
    public init(kind: Kind) {
        self.kind = kind
    }
}
