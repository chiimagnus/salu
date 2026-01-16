import XCTest
@testable import GameCore

final class BattleEventDescriptionTests: XCTestCase {
    func testBattleEvent_description_coversAllCases() {
        print("🧪 测试：testBattleEvent_description_coversAllCases")
        
        let events: [(BattleEvent, String)] = [
            (.battleStarted, "战斗开始"),
            (.turnStarted(turn: 1), "第 1 回合"),
            (.energyReset(amount: 3), "能量"),
            (.blockCleared(target: LocalizedText("玩家", "玩家"), amount: 5), "玩家"),
            (.drew(cardId: "strike"), "抽到"),
            (.shuffled(count: 5), "洗牌"),
            (.played(cardInstanceId: "strike_1", cardId: "strike", cost: 1), "打出"),
            (.damageDealt(source: LocalizedText("玩家", "玩家"), target: LocalizedText("敌人", "敌人"), amount: 6, blocked: 0), "造成"),
            (.damageDealt(source: LocalizedText("玩家", "玩家"), target: LocalizedText("敌人", "敌人"), amount: 6, blocked: 3), "被格挡"),
            (.blockGained(target: LocalizedText("玩家", "玩家"), amount: 5), "格挡"),
            (.handDiscarded(count: 3), "弃置"),
            (.enemyIntent(enemyId: "e", action: LocalizedText("攻击", "Attack"), damage: 10), "敌人意图"),
            (.enemyAction(enemyId: "e", action: LocalizedText("攻击", "Attack")), "执行"),
            (.turnEnded(turn: 1), "回合结束"),
            (.entityDied(entityId: "e", name: LocalizedText("敌人", "敌人")), "死亡"),
            (.battleWon, "胜利"),
            (.battleLost, "失败"),
            (.notEnoughEnergy(required: 2, available: 1), "能量不足"),
            (.invalidAction(reason: LocalizedText("测试", "Test")), "无效操作"),
            (.statusApplied(target: LocalizedText("玩家", "玩家"), effect: LocalizedText("易伤", "Vulnerable"), stacks: 2), "获得"),
            (.statusExpired(target: LocalizedText("玩家", "玩家"), effect: LocalizedText("易伤", "Vulnerable")), "消退"),
        ]
        
        for (event, expected) in events {
            let desc = event.description
            XCTAssertFalse(desc.isEmpty)
            XCTAssertTrue(desc.contains(expected), "期望描述包含关键字：\(expected)（实际：\(desc)）")
        }
    }
}
