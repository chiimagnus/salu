import XCTest
@testable import GameCore

/// 商店系统单元测试
final class ShopTests: XCTestCase {
    func testShopPricing_forCommonCard() {
        print("🧪 测试：testShopPricing_forCommonCard")
        let price = ShopPricing.cardPrice(for: "pommel_strike")
        XCTAssertEqual(price, 45)
    }
    
    func testShopPricing_forStarterCard() {
        print("🧪 测试：testShopPricing_forStarterCard")
        let price = ShopPricing.cardPrice(for: "strike")
        XCTAssertEqual(price, 30)
    }
    
    func testShopInventory_generate_isDeterministic() {
        print("🧪 测试：testShopInventory_generate_isDeterministic")
        let context = ShopContext(seed: 42, floor: 1, currentRow: 3, nodeId: "3_0")
        let a = ShopInventory.generate(context: context)
        let b = ShopInventory.generate(context: context)
        
        XCTAssertEqual(a, b)
        XCTAssertEqual(Set(a.cardOffers.map(\.cardId)), Set(b.cardOffers.map(\.cardId)))
    }
    
    func testShopInventory_generate_hasNoDuplicateCards() {
        print("🧪 测试：testShopInventory_generate_hasNoDuplicateCards")
        let context = ShopContext(seed: 99, floor: 1, currentRow: 4, nodeId: "4_0")
        let inventory = ShopInventory.generate(context: context)
        let ids = inventory.cardOffers.map(\.cardId)
        
        XCTAssertEqual(ids.count, Set(ids).count)
    }
}
