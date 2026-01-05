import XCTest
@testable import GameCore

/// RewardGenerator（战斗后奖励）单元测试
///
/// 目的：
/// - 确认奖励生成是**可复现**的（同 context → 同结果）
/// - 确认奖励候选满足基础规则（去重、排除起始牌）
final class RewardGeneratorTests: XCTestCase {
    /// 同一个 `RewardContext` 重复生成奖励，结果必须一致（可复现性）。
    func testGenerateCardReward_isDeterministic() {
        print("🧪 测试：testGenerateCardReward_isDeterministic")
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
    
    /// 生成的候选卡牌必须：
    /// - 数量不超过 3
    /// - 同一次 offer 内不重复
    /// - 不包含起始牌（starter）
    func testGenerateCardReward_choicesAreUniqueAndNonStarter() {
        print("🧪 测试：testGenerateCardReward_choicesAreUniqueAndNonStarter")
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


