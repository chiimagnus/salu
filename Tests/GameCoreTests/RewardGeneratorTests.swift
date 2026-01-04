import XCTest
@testable import GameCore

final class RewardGeneratorTests: XCTestCase {
    func testGenerateCardReward_isDeterministic() {
        let context = RewardContext(
            seed: 123,
            floor: 1,
            currentRow: 1,
            nodeId: "1_0",
            roomType: .battle
        )
        
        let a = RewardGenerator.generateCardReward(context: context)
        let b = RewardGenerator.generateCardReward(context: context)
        
        XCTAssertEqual(a, b)
    }
    
    func testGenerateCardReward_choicesAreUniqueAndNonStarter() {
        let context = RewardContext(
            seed: 42,
            floor: 1,
            currentRow: 3,
            nodeId: "3_0",
            roomType: .elite
        )
        
        let offer = RewardGenerator.generateCardReward(context: context)
        XCTAssertLessThanOrEqual(offer.choices.count, 3)
        
        // 去重
        XCTAssertEqual(Set(offer.choices.map(\.rawValue)).count, offer.choices.count)
        
        // 不包含 starter 卡
        for id in offer.choices {
            let def = CardRegistry.require(id)
            XCTAssertNotEqual(def.rarity, .starter)
        }
    }
}


