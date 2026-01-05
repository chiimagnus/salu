import XCTest
@testable import GameCore

final class StatusDefinitionDefaultImplementationTests: XCTestCase {
    func testDefaultImplementations_areIdentityAndEmpty() {
        print("🧪 测试：testDefaultImplementations_areIdentityAndEmpty")
        XCTAssertNil(DummyStatus.outgoingDamagePhase)
        XCTAssertNil(DummyStatus.incomingDamagePhase)
        XCTAssertNil(DummyStatus.blockPhase)
        XCTAssertEqual(DummyStatus.priority, 0)
        
        XCTAssertEqual(DummyStatus.modifyOutgoingDamage(10, stacks: 3), 10)
        XCTAssertEqual(DummyStatus.modifyIncomingDamage(10, stacks: 3), 10)
        XCTAssertEqual(DummyStatus.modifyBlock(10, stacks: 3), 10)
        
        let player = Entity(id: "player", name: "玩家", maxHP: 80)
        let enemy = Entity(id: "enemy", name: "敌人", maxHP: 40, enemyId: "jaw_worm")
        let snapshot = BattleSnapshot(turn: 1, player: player, enemy: enemy, energy: 3)
        XCTAssertEqual(DummyStatus.onTurnEnd(owner: .player, stacks: 1, snapshot: snapshot).count, 0)
    }
}

private struct DummyStatus: StatusDefinition {
    static let id: StatusID = "dummy"
    static let name: String = "假状态"
    static let icon: String = "❔"
    static let isPositive: Bool = true
    static let decay: StatusDecay = .none
}


