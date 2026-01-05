import XCTest
@testable import GameCore

final class ShopItemTests: XCTestCase {
    func testShopItem_equatableAndInit() {
        print("🧪 测试：testShopItem_equatableAndInit")
        let offer = ShopCardOffer(cardId: "pommel_strike", price: 45)
        
        let a = ShopItem(kind: .card(offer))
        let b = ShopItem(kind: .card(offer))
        XCTAssertEqual(a, b)
        
        let c = ShopItem(kind: .removeCard(price: 75))
        XCTAssertNotEqual(a, c)
    }
}


