import XCTest
@testable import GameCore

/// 遗物掉落策略测试
final class RelicDropStrategyTests: XCTestCase {
    func testRelicPool_excludesStarterAndOwned() {
        print("🧪 测试：testRelicPool_excludesStarterAndOwned")
        let pool = RelicPool.availableRelicIds(excluding: ["burning_blood"])
        
        XCTAssertFalse(pool.contains("burning_blood"))
        for relicId in pool {
            XCTAssertNotEqual(RelicRegistry.require(relicId).rarity, .starter)
        }
        
        let poolAfterOwned = RelicPool.availableRelicIds(excluding: ["lantern"])
        XCTAssertFalse(poolAfterOwned.contains("lantern"))
    }
    
    func testRelicDrop_isDeterministicAndRespectsExclusion() {
        print("🧪 测试：testRelicDrop_isDeterministicAndRespectsExclusion")
        let context = RewardContext(
            seed: 123,
            floor: 1,
            currentRow: 1,
            nodeId: "1_0",
            roomType: .elite
        )
        
        let owned: [RelicID] = ["lantern"]
        let first = RelicDropStrategy.generateRelicDrop(
            context: context,
            source: .elite,
            ownedRelics: owned
        )
        let second = RelicDropStrategy.generateRelicDrop(
            context: context,
            source: .elite,
            ownedRelics: owned
        )
        
        XCTAssertEqual(first, second)
        XCTAssertNotEqual(first, "lantern")
    }

    func testBossRelicDrop_prefersBossRarity_whenAvailable() {
        print("🧪 测试：testBossRelicDrop_prefersBossRarity_whenAvailable")
        let context = RewardContext(
            seed: 777,
            floor: 1,
            currentRow: 14,
            nodeId: "14_0",
            roomType: .boss
        )
        
        let drop = RelicDropStrategy.generateRelicDrop(
            context: context,
            source: .boss,
            ownedRelics: []
        )
        
        XCTAssertNotNil(drop)
        if let drop {
            XCTAssertEqual(RelicRegistry.require(drop).rarity, .boss)
        }
    }
}
