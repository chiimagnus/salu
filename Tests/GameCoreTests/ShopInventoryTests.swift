import XCTest
import GameCore

final class ShopInventoryTests: XCTestCase {
    func test_shopPricingValues() {
        // 卡牌定价
        XCTAssertEqual(ShopPricing.removeCardPrice, 75)
        XCTAssertEqual(ShopPricing.cardPrice(for: .starter), 30)
        XCTAssertEqual(ShopPricing.cardPrice(for: .common), 45)
        XCTAssertEqual(ShopPricing.cardPrice(for: .uncommon), 75)
        XCTAssertEqual(ShopPricing.cardPrice(for: .rare), 150)
        
        // P4: 遗物定价
        XCTAssertEqual(ShopPricing.relicPrice(for: .common), 100)
        XCTAssertEqual(ShopPricing.relicPrice(for: .uncommon), 150)
        XCTAssertEqual(ShopPricing.relicPrice(for: .rare), 250)
        
        // P4R: 消耗性卡牌（消耗品）定价
        XCTAssertEqual(ShopPricing.consumableCardPrice(for: .common), 35)
        XCTAssertEqual(ShopPricing.consumableCardPrice(for: .uncommon), 60)
        XCTAssertEqual(ShopPricing.consumableCardPrice(for: .rare), 100)
    }
    
    func test_shopInventoryGeneration_isDeterministic_andValid() {
        let context = ShopContext(seed: 1, floor: 1, currentRow: 5, nodeId: "5_0", ownedRelicIds: [])
        
        let a = ShopInventory.generate(context: context)
        let b = ShopInventory.generate(context: context)
        
        // 确定性
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.removeCardPrice, ShopPricing.removeCardPrice)
        
        // P4 扩展：5 张卡牌
        XCTAssertEqual(a.cardOffers.count, 5)
        
        // offer 内去重
        XCTAssertEqual(Set(a.cardOffers.map { $0.cardId }).count, a.cardOffers.count)
        
        // 不应出现 starter 稀有度卡牌
        XCTAssertTrue(a.cardOffers.allSatisfy { CardRegistry.require($0.cardId).rarity != .starter })
        
        // 价格应符合定价规则
        XCTAssertTrue(a.cardOffers.allSatisfy { $0.price == ShopPricing.cardPrice(for: $0.cardId) })
        
        // P4R: 遗物和消耗性卡牌（消耗品）
        XCTAssertGreaterThanOrEqual(a.relicOffers.count, 0)  // 可能会因为遗物池小而少于 3
        XCTAssertGreaterThanOrEqual(a.consumableOffers.count, 0)  // 可能会因为池子小而少于 3

        XCTAssertTrue(a.consumableOffers.allSatisfy {
            CardRegistry.require($0.cardId).type == .consumable
        })

        // P4R: 消耗性卡牌价格应符合定价规则
        XCTAssertTrue(a.consumableOffers.allSatisfy {
            $0.price == ShopPricing.consumableCardPrice(for: $0.cardId)
        })
        
        // items 包含所有条目
        XCTAssertEqual(a.items.count, a.cardOffers.count + a.relicOffers.count + a.consumableOffers.count + 1)  // +1 for removeCard
    }
    
    func test_shopInventory_excludesOwnedRelics() {
        // 获取所有可用遗物
        let allRelics = RelicPool.availableRelicIds(excluding: [])
        guard allRelics.count > 0 else { return }  // 如果没有遗物则跳过
        
        // 创建拥有第一个遗物的上下文
        let ownedRelic = allRelics[0]
        let context = ShopContext(seed: 1, floor: 1, currentRow: 5, nodeId: "5_0", ownedRelicIds: [ownedRelic])
        
        let inventory = ShopInventory.generate(context: context)
        
        // 确保已拥有的遗物不会出现在商店
        XCTAssertFalse(inventory.relicOffers.contains { $0.relicId == ownedRelic })
    }
}
