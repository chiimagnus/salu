import XCTest
@testable import GameCore

final class GoldRewardStrategyTests: XCTestCase {
    func testGoldReward_isDeterministic_forBattle() {
        let context = RewardContext(seed: 123, floor: 1, currentRow: 2, nodeId: "2_0", roomType: .battle)
        let a = GoldRewardStrategy.generateGoldReward(context: context)
        let b = GoldRewardStrategy.generateGoldReward(context: context)
        XCTAssertEqual(a, b)
        XCTAssertTrue((10...20).contains(a))
    }
    
    func testGoldReward_isDeterministic_forElite() {
        let context = RewardContext(seed: 123, floor: 1, currentRow: 2, nodeId: "2_0", roomType: .elite)
        let a = GoldRewardStrategy.generateGoldReward(context: context)
        let b = GoldRewardStrategy.generateGoldReward(context: context)
        XCTAssertEqual(a, b)
        XCTAssertTrue((25...35).contains(a))
    }
}


