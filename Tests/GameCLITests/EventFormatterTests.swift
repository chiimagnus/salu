import XCTest
@testable import GameCLI
@testable import GameCore

final class EventFormatterTests: XCTestCase {
    func testFormat_coversAllBattleEventCases() {
        print("🧪 测试：testFormat_coversAllBattleEventCases")
        let events: [BattleEvent] = [
            .battleStarted,
            .turnStarted(turn: 1),
            .energyReset(amount: 3),
            .blockCleared(target: "铁甲战士", amount: 5),
            .drew(cardId: "strike"),
            .shuffled(count: 10),
            .played(cardId: "strike", cost: 1),
            .damageDealt(source: "铁甲战士", target: "敌人", amount: 6, blocked: 0),
            .damageDealt(source: "铁甲战士", target: "敌人", amount: 6, blocked: 3),
            .damageDealt(source: "铁甲战士", target: "敌人", amount: 0, blocked: 6),
            .blockGained(target: "铁甲战士", amount: 5),
            .handDiscarded(count: 3),
            .enemyIntent(enemyId: "slime_medium_acid", action: "攻击", damage: 10),
            .enemyAction(enemyId: "slime_medium_acid", action: "攻击"),
            .turnEnded(turn: 1),
            .entityDied(entityId: "enemy", name: "酸液史莱姆"),
            .battleWon,
            .battleLost,
            .notEnoughEnergy(required: 2, available: 1),
            .invalidAction(reason: "无效"),
            .statusApplied(target: "铁甲战士", effect: "易伤", stacks: 2),
            .statusExpired(target: "铁甲战士", effect: "易伤"),
        ]
        
        for e in events {
            let text = EventFormatter.format(e)
            if case .enemyIntent = e {
                XCTAssertEqual(text, "", "enemyIntent 不应重复显示（已在界面上展示）")
                continue
            }
            XCTAssertFalse(text.isEmpty, "事件 \(e) 应输出非空文本")
        }
        
        // 覆盖伤害分支关键字
        let fullBlock = EventFormatter.format(.damageDealt(source: "A", target: "B", amount: 0, blocked: 3))
        XCTAssertTrue(fullBlock.contains("完全格挡"), "完全格挡分支应包含提示文案")
        
        let partialBlock = EventFormatter.format(.damageDealt(source: "A", target: "B", amount: 2, blocked: 1))
        XCTAssertTrue(partialBlock.contains("格挡"), "部分格挡分支应包含格挡信息")
    }
}


