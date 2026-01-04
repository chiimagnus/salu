import XCTest
@testable import GameCore

/// BattleEvent.description 文案测试
///
/// 目的：
/// - 让 `Sources/GameCore/Events.swift` 的描述分支被执行（覆盖率缺口）
/// - 防止 UI 依赖的事件文案在重构时被意外改坏/改空
final class BattleEventDescriptionTests: XCTestCase {
    func testBattleStarted_description_isStable() {
        XCTAssertEqual(BattleEvent.battleStarted.description, "⚔️ 战斗开始！")
    }
    
    func testTurnStarted_description_containsTurnNumber() {
        XCTAssertTrue(BattleEvent.turnStarted(turn: 2).description.contains("第 2 回合"))
    }
    
    func testDrewAndPlayed_description_resolvesCardNameFromRegistry() {
        XCTAssertEqual(BattleEvent.drew(cardId: "strike").description, "🃏 抽到 打击")
        XCTAssertEqual(BattleEvent.played(cardId: "bash", cost: 2).description, "▶️ 打出 重击（消耗 2 能量）")
    }
    
    func testDamageDealt_description_handlesBlockedAndUnblocked() {
        XCTAssertEqual(
            BattleEvent.damageDealt(source: "玩家", target: "敌人", amount: 6, blocked: 0).description,
            "💥 玩家 对 敌人 造成 6 伤害"
        )
        XCTAssertEqual(
            BattleEvent.damageDealt(source: "玩家", target: "敌人", amount: 2, blocked: 5).description,
            "💥 玩家 对 敌人 造成 2 伤害（5 被格挡）"
        )
    }
    
    func testNotEnoughEnergyAndInvalidAction_description_isNonEmpty() {
        XCTAssertFalse(BattleEvent.notEnoughEnergy(required: 2, available: 1).description.isEmpty)
        XCTAssertFalse(BattleEvent.invalidAction(reason: "测试").description.isEmpty)
    }
}


