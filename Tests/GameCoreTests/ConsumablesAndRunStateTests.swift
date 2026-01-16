import XCTest
import GameCore

final class ConsumablesAndRunStateTests: XCTestCase {
    func testCardRegistry_canResolveKnownConsumableCards() {
        XCTAssertEqual(CardRegistry.require("purification_rune").type, .consumable)
        XCTAssertEqual(CardRegistry.require("healing_potion").type, .consumable)
        XCTAssertEqual(CardRegistry.require("block_potion").type, .consumable)
        XCTAssertEqual(CardRegistry.require("strength_potion").type, .consumable)
    }
    
    func testRunState_addConsumableCardToDeck_respectsMaxSlots() {
        var run = RunState.newRun(seed: 1)
        XCTAssertEqual(run.consumableCardCount, 0)
        
        XCTAssertTrue(run.addConsumableCardToDeck(cardId: "healing_potion"))
        XCTAssertTrue(run.addConsumableCardToDeck(cardId: "block_potion"))
        XCTAssertTrue(run.addConsumableCardToDeck(cardId: "purification_rune"))
        XCTAssertEqual(run.consumableCardCount, 3)
        
        // 第 4 个应该失败
        XCTAssertFalse(run.addConsumableCardToDeck(cardId: "strength_potion"))
        XCTAssertEqual(run.consumableCardCount, 3)
    }
    
    func testPurificationRune_clearsAllMadnessInBattle() {
        // 消耗性卡牌定义是纯函数：只要产出 clearMadness(amount: 0) 即代表“清除所有疯狂”
        let effects = PurificationRune.play(snapshot: BattleSnapshot(
            turn: 1,
            player: createDefaultPlayer(),
            enemies: [Entity(id: "e0", name: LocalizedText("测试敌人", "测试敌人"), maxHP: 10, enemyId: "shadow_stalker")],
            energy: 3
        ), targetEnemyIndex: nil)
        let expected: [BattleEffect] = [.clearMadness(amount: 0)]
        XCTAssertEqual(effects, expected)
    }
}
