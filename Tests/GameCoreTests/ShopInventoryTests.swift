import XCTest
import GameCore

final class ShopInventoryTests: XCTestCase {
    func test_shopPricingValues() {
        XCTAssertEqual(ShopPricing.removeCardPrice, 75)
        XCTAssertEqual(ShopPricing.cardPrice(for: .starter), 30)
        XCTAssertEqual(ShopPricing.cardPrice(for: .common), 45)
        XCTAssertEqual(ShopPricing.cardPrice(for: .uncommon), 75)
        XCTAssertEqual(ShopPricing.cardPrice(for: .rare), 150)
    }
    
    func test_shopInventoryGeneration_isDeterministic_andValid() {
        let context = ShopContext(seed: 1, floor: 1, currentRow: 5, nodeId: "5_0")
        
        let a = ShopInventory.generate(context: context)
        let b = ShopInventory.generate(context: context)
        
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.removeCardPrice, ShopPricing.removeCardPrice)
        XCTAssertEqual(a.cardOffers.count, 3)
        
        // offer 内去重
        XCTAssertEqual(Set(a.cardOffers.map { $0.cardId }).count, a.cardOffers.count)
        
        // 不应出现 starter 稀有度卡牌
        XCTAssertTrue(a.cardOffers.allSatisfy { CardRegistry.require($0.cardId).rarity != .starter })
        
        // 价格应符合定价规则
        XCTAssertTrue(a.cardOffers.allSatisfy { $0.price == ShopPricing.cardPrice(for: $0.cardId) })
    }
}


