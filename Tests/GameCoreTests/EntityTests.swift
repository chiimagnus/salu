import XCTest
@testable import GameCore

final class EntityTests: XCTestCase {
    func testInit_playerAndEnemy() {
        print("🧪 测试：testInit_playerAndEnemy")
        let player = Entity(id: "p", name: LocalizedText("玩家", "玩家"), maxHP: 80)
        XCTAssertEqual(player.currentHP, 80)
        XCTAssertNil(player.enemyId)
        XCTAssertNil(player.plannedMove)
        
        let enemy = Entity(id: "e", name: LocalizedText("敌人", "敌人"), maxHP: 10, enemyId: "jaw_worm")
        XCTAssertEqual(enemy.currentHP, 10)
        XCTAssertEqual(enemy.enemyId, EnemyID("jaw_worm"))
    }
    
    func testTakeDamage_blockAndHP() {
        print("🧪 测试：testTakeDamage_blockAndHP")
        var e = Entity(id: "p", name: LocalizedText("玩家", "玩家"), maxHP: 10)
        
        // 非正数不生效
        XCTAssertEqual(e.takeDamage(0).dealt, 0)
        XCTAssertEqual(e.takeDamage(-1).dealt, 0)
        
        // 有格挡时先扣格挡
        e.gainBlock(5)
        XCTAssertEqual(e.block, 5)
        let r1 = e.takeDamage(3)
        XCTAssertEqual(r1.dealt, 0)
        XCTAssertEqual(r1.blocked, 3)
        XCTAssertEqual(e.block, 2)
        XCTAssertEqual(e.currentHP, 10)
        
        // 部分格挡
        let r2 = e.takeDamage(6)
        XCTAssertEqual(r2.dealt, 4)
        XCTAssertEqual(r2.blocked, 2)
        XCTAssertEqual(e.block, 0)
        XCTAssertEqual(e.currentHP, 6)
        
        // HP 不低于 0
        let r3 = e.takeDamage(999)
        XCTAssertEqual(r3.dealt, 999) // remainingDamage
        XCTAssertEqual(e.currentHP, 0)
        XCTAssertFalse(e.isAlive)
    }
    
    func testGainAndClearBlock() {
        print("🧪 测试：testGainAndClearBlock")
        var e = Entity(id: "p", name: LocalizedText("玩家", "玩家"), maxHP: 10)
        e.gainBlock(0)
        e.gainBlock(-1)
        XCTAssertEqual(e.block, 0)
        e.gainBlock(3)
        XCTAssertEqual(e.block, 3)
        e.clearBlock()
        XCTAssertEqual(e.block, 0)
    }
    
    func testCreateDefaultPlayer() {
        print("🧪 测试：testCreateDefaultPlayer")
        let p = createDefaultPlayer()
        XCTAssertEqual(p.id, "player")
        XCTAssertEqual(p.name.zhHans, "安德")
        XCTAssertEqual(p.maxHP, 80)
        XCTAssertEqual(p.currentHP, 80)
    }
}

