import XCTest
import GameCore

final class ConsumablesAndRunStateTests: XCTestCase {
    func testConsumableRegistry_canResolveKnownConsumables() {
        XCTAssertNotNil(ConsumableRegistry.get("purification_rune"))
        XCTAssertNotNil(ConsumableRegistry.get("healing_potion"))
        XCTAssertNotNil(ConsumableRegistry.get("block_potion"))
        XCTAssertNotNil(ConsumableRegistry.get("strength_potion"))
    }
    
    func testRunState_addConsumable_respectsMaxSlots() {
        var run = RunState.newRun(seed: 1)
        XCTAssertEqual(run.consumables.count, 0)
        
        XCTAssertTrue(run.addConsumable("healing_potion"))
        XCTAssertTrue(run.addConsumable("block_potion"))
        XCTAssertTrue(run.addConsumable("purification_rune"))
        XCTAssertEqual(run.consumables.count, 3)
        
        // 第 4 个应该失败
        XCTAssertFalse(run.addConsumable("strength_potion"))
        XCTAssertEqual(run.consumables.count, 3)
    }
    
    func testPurificationRune_clearsAllMadnessInBattle() {
        // 消耗品定义是纯函数：只要产出 clearMadness(amount: 0) 即代表“清除所有疯狂”
        let effects = PurificationRuneConsumable.useInBattle(snapshot: BattleSnapshot(
            turn: 1,
            player: createDefaultPlayer(),
            enemies: [Entity(id: "e0", name: "测试敌人", maxHP: 10, enemyId: "shadow_stalker")],
            energy: 3
        ))
        XCTAssertEqual(effects, [.clearMadness(amount: 0)])
    }
}

