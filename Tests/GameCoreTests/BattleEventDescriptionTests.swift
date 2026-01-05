import XCTest
@testable import GameCore

/// BattleEvent.description 文案测试
///
/// 目的：
/// - 让 `Sources/GameCore/Events.swift` 的描述分支被执行（覆盖率缺口）
/// - 防止 UI 依赖的事件文案在重构时被意外改坏/改空
final class BattleEventDescriptionTests: XCTestCase {
    func testBattleStarted_description_isStable() {
        print("🧪 测试：testBattleStarted_description_isStable")
        XCTAssertEqual(BattleEvent.battleStarted.description, "⚔️ 战斗开始！")
    }
    
    func testTurnStarted_description_containsTurnNumber() {
    
        print("🧪 测试：testTurnStarted_description_containsTurnNumber")
        XCTAssertTrue(BattleEvent.turnStarted(turn: 2).description.contains("第 2 回合"))
    }
    
    func testDrewAndPlayed_description_resolvesCardNameFromRegistry() {
    
        print("🧪 测试：testDrewAndPlayed_description_resolvesCardNameFromRegistry")
        XCTAssertEqual(BattleEvent.drew(cardId: "strike").description, "🃏 抽到 打击")
        XCTAssertEqual(BattleEvent.played(cardId: "bash", cost: 2).description, "▶️ 打出 重击（消耗 2 能量）")
    }
    
    func testDamageDealt_description_handlesBlockedAndUnblocked() {
    
        print("🧪 测试：testDamageDealt_description_handlesBlockedAndUnblocked")
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
    
        print("🧪 测试：testNotEnoughEnergyAndInvalidAction_description_isNonEmpty")
        XCTAssertFalse(BattleEvent.notEnoughEnergy(required: 2, available: 1).description.isEmpty)
        XCTAssertFalse(BattleEvent.invalidAction(reason: "测试").description.isEmpty)
    }

    func testAllEventCases_description_isNonEmptyAndStableFormat() {
        print("🧪 测试：testAllEventCases_description_isNonEmptyAndStableFormat")
        
        let cases: [BattleEvent] = [
            .battleStarted,
            .turnStarted(turn: 1),
            .energyReset(amount: 3),
            .blockCleared(target: "玩家", amount: 5),
            .drew(cardId: "strike"),
            .shuffled(count: 10),
            .played(cardId: "defend", cost: 1),
            .damageDealt(source: "玩家", target: "敌人", amount: 6, blocked: 0),
            .damageDealt(source: "玩家", target: "敌人", amount: 1, blocked: 2),
            .blockGained(target: "玩家", amount: 8),
            .handDiscarded(count: 5),
            .enemyIntent(enemyId: "slime_medium_acid", action: "攻击", damage: 10),
            .enemyAction(enemyId: "slime_medium_acid", action: "攻击"),
            .turnEnded(turn: 1),
            .entityDied(entityId: "enemy", name: "酸液史莱姆"),
            .battleWon,
            .battleLost,
            .notEnoughEnergy(required: 2, available: 1),
            .invalidAction(reason: "无效"),
            .statusApplied(target: "玩家", effect: "易伤", stacks: 2),
            .statusExpired(target: "玩家", effect: "易伤"),
        ]
        
        for e in cases {
            XCTAssertFalse(e.description.isEmpty, "BattleEvent \(e) 的 description 不应为空")
        }
        
        // 关键分支：enemyIntent 文案包含 action 与 damage
        let intent = BattleEvent.enemyIntent(enemyId: "x", action: "攻击", damage: 7).description
        XCTAssertTrue(intent.contains("攻击"))
        XCTAssertTrue(intent.contains("7"))
    }
}


