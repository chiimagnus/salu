import XCTest
@testable import GameCore

/// RunState 牌组（deck）相关单元测试
///
/// 目的：
/// - 验证 P1 奖励接入后“新增卡牌实例 ID”的生成规则稳定
final class RunStateDeckTests: XCTestCase {
    /// `RunState.addCardToDeck(cardId:)` 应当生成稳定且不冲突的实例 ID：
    /// - 规则：`<cardId.rawValue>_<n>`（n 为同 cardId 的序号）
    func testAddCardToDeck_generatesStableInstanceId() {
        print("🧪 测试：testAddCardToDeck_generatesStableInstanceId")
        var runState = RunState.newRun(seed: 1)
        
        // starter deck 本来就有 inflame_1
        runState.addCardToDeck(cardId: "inflame")
        
        guard let last = runState.deck.last else {
            XCTFail("deck 为空")
            return
        }
        
        XCTAssertEqual(last.cardId.rawValue, "inflame")
        XCTAssertEqual(last.id, "inflame_2")
    }
    
    func testUpgradeableCardIndices_filtersUpgradeableCards() {
        print("🧪 测试：testUpgradeableCardIndices_filtersUpgradeableCards")
        let deck: [Card] = [
            Card(id: "strike_1", cardId: "strike"),
            Card(id: "inflame_1", cardId: "inflame"),
            Card(id: "defend_1", cardId: "defend"),
            Card(id: "bash_1", cardId: "bash+")
        ]
        
        let indices = RunState.upgradeableCardIndices(in: deck)
        
        XCTAssertEqual(indices, [0, 2])
    }
    
    func testUpgradeCard_replacesCardIdAndKeepsInstanceId() {
        print("🧪 测试：testUpgradeCard_replacesCardIdAndKeepsInstanceId")
        var runState = RunState.newRun(seed: 1)
        let originalId = runState.deck[0].id
        
        let upgraded = runState.upgradeCard(at: 0)
        
        XCTAssertTrue(upgraded)
        XCTAssertEqual(runState.deck[0].id, originalId)
        XCTAssertEqual(runState.deck[0].cardId.rawValue, "strike+")
    }
}

