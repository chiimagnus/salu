import XCTest
@testable import GameCore

final class RunEffectTests: XCTestCase {
    func testApply_gainAndLoseGold_clampsAtZero() {
        print("🧪 测试：testApply_gainAndLoseGold_clampsAtZero")
        var run = RunState.newRun(seed: 1)
        run.gold = 10
        
        XCTAssertTrue(run.apply(.gainGold(amount: 5)))
        XCTAssertEqual(run.gold, 15)
        
        XCTAssertTrue(run.apply(.loseGold(amount: 7)))
        XCTAssertEqual(run.gold, 8)
        
        XCTAssertTrue(run.apply(.loseGold(amount: 999)))
        XCTAssertEqual(run.gold, 0)
    }
    
    func testApply_healAndDamage_clampsAndCanEndRun() {
        print("🧪 测试：testApply_healAndDamage_clampsAndCanEndRun")
        var run = RunState.newRun(seed: 1)
        run.player.currentHP = 10
        
        XCTAssertTrue(run.apply(.heal(amount: 999)))
        XCTAssertEqual(run.player.currentHP, run.player.maxHP)
        
        XCTAssertTrue(run.apply(.takeDamage(amount: 1)))
        XCTAssertEqual(run.player.currentHP, run.player.maxHP - 1)
        XCTAssertFalse(run.isOver)
        
        XCTAssertTrue(run.apply(.takeDamage(amount: 9999)))
        XCTAssertEqual(run.player.currentHP, 0)
        XCTAssertTrue(run.isOver)
        XCTAssertFalse(run.won)
    }
    
    func testApply_addCard_addsToDeckWithInstanceId() {
        print("🧪 测试：testApply_addCard_addsToDeckWithInstanceId")
        var run = RunState.newRun(seed: 1)
        let oldCount = run.deck.count
        
        XCTAssertTrue(run.apply(.addCard(cardId: "pommel_strike")))
        XCTAssertEqual(run.deck.count, oldCount + 1)
        XCTAssertEqual(run.deck.last?.cardId, CardID("pommel_strike"))
        XCTAssertTrue(run.deck.last?.id.hasPrefix("pommel_strike_") == true)
    }
    
    func testApply_addRelic_doesNotDuplicate() {
        print("🧪 测试：testApply_addRelic_doesNotDuplicate")
        var run = RunState.newRun(seed: 1)
        let before = run.relicManager.all.count
        
        XCTAssertTrue(run.apply(.addRelic(relicId: "vajra")))
        XCTAssertEqual(run.relicManager.all.count, before + 1)
        
        XCTAssertTrue(run.apply(.addRelic(relicId: "vajra")))
        XCTAssertEqual(run.relicManager.all.count, before + 1)
    }
    
    func testApply_upgradeCard_upgradesWhenPossible() {
        print("🧪 测试：testApply_upgradeCard_upgradesWhenPossible")
        var run = RunState.newRun(seed: 1)
        // 起始牌组中 strike_1 在索引 0，且可升级
        XCTAssertEqual(run.deck.first?.id, "strike_1")
        XCTAssertEqual(run.deck.first?.cardId, CardID("strike"))
        
        XCTAssertTrue(run.apply(.upgradeCard(deckIndex: 0)))
        XCTAssertEqual(run.deck.first?.id, "strike_1")
        XCTAssertEqual(run.deck.first?.cardId, CardID("strike+"))
    }
}


