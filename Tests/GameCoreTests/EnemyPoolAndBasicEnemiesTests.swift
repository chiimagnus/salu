import XCTest
@testable import GameCore

final class EnemyPoolAndBasicEnemiesTests: XCTestCase {
    func testEnemyPool_randomPickWithinPools() {
        print("🧪 测试：testEnemyPool_randomPickWithinPools")
        var rng = SeededRNG(seed: 1)
        let w = Act1EnemyPool.randomWeak(rng: &rng)
        XCTAssertTrue(Act1EnemyPool.weak.contains(w))
        
        let m = Act1EnemyPool.randomMedium(rng: &rng)
        XCTAssertTrue(Act1EnemyPool.medium.contains(m))
        
        let any = Act1EnemyPool.randomAny(rng: &rng)
        XCTAssertTrue(Act1EnemyPool.all.contains(any))
    }
    
    func testCreateEnemy_hpRange() {
        print("🧪 测试：testCreateEnemy_hpRange")
        var rng = SeededRNG(seed: 123)
        let enemy = createEnemy(enemyId: "jaw_worm", rng: &rng)
        XCTAssertTrue((40...44).contains(enemy.maxHP))
        XCTAssertEqual(enemy.currentHP, enemy.maxHP)
        XCTAssertEqual(enemy.enemyId, EnemyID("jaw_worm"))
    }
    
    func testBasicEnemies_chooseMove_coversBranches() {
        print("🧪 测试：testBasicEnemies_chooseMove_coversBranches")
        let player = Entity(id: "player", name: "玩家", maxHP: 80)
        let enemy = Entity(id: "enemy", name: "敌人", maxHP: 40, enemyId: "jaw_worm")
        
        // JawWorm turn 1: bite or strength
        XCTAssertTrue(findSeed { rollSeed in
            var rng = SeededRNG(seed: rollSeed)
            let snap = BattleSnapshot(turn: 1, player: player, enemy: enemy, energy: 3)
            return JawWorm.chooseMove(snapshot: snap, rng: &rng).intent.text.contains("攻击")
        } != nil)
        
        XCTAssertTrue(findSeed { rollSeed in
            var rng = SeededRNG(seed: rollSeed)
            let snap = BattleSnapshot(turn: 1, player: player, enemy: enemy, energy: 3)
            return JawWorm.chooseMove(snapshot: snap, rng: &rng).intent.text.contains("力量")
        } != nil)
        
        // JawWorm later turns: three options (attack 11 / strength / pounce 7)
        XCTAssertTrue(findSeed { rollSeed in
            var rng = SeededRNG(seed: rollSeed)
            let snap = BattleSnapshot(turn: 2, player: player, enemy: enemy, energy: 3)
            return JawWorm.chooseMove(snapshot: snap, rng: &rng).intent.text.contains("攻击 11")
        } != nil)
        
        XCTAssertTrue(findSeed { rollSeed in
            var rng = SeededRNG(seed: rollSeed)
            let snap = BattleSnapshot(turn: 2, player: player, enemy: enemy, energy: 3)
            return JawWorm.chooseMove(snapshot: snap, rng: &rng).intent.text.contains("力量")
        } != nil)
        
        XCTAssertTrue(findSeed { rollSeed in
            var rng = SeededRNG(seed: rollSeed)
            let snap = BattleSnapshot(turn: 2, player: player, enemy: enemy, energy: 3)
            return JawWorm.chooseMove(snapshot: snap, rng: &rng).intent.text.contains("猛扑")
        } != nil)
        
        // Cultist: turn 1 strength, later attack
        do {
            var rng = SeededRNG(seed: 1)
            let snap1 = BattleSnapshot(turn: 1, player: player, enemy: enemy, energy: 3)
            XCTAssertTrue(Cultist.chooseMove(snapshot: snap1, rng: &rng).intent.text.contains("力量"))
            let snap2 = BattleSnapshot(turn: 2, player: player, enemy: enemy, energy: 3)
            XCTAssertTrue(Cultist.chooseMove(snapshot: snap2, rng: &rng).intent.text.contains("攻击"))
        }
        
        // Louse (green/red): attack or curl
        XCTAssertTrue(findSeed { rollSeed in
            var rng = SeededRNG(seed: rollSeed)
            let snap = BattleSnapshot(turn: 2, player: player, enemy: enemy, energy: 3)
            return LouseGreen.chooseMove(snapshot: snap, rng: &rng).intent.text.contains("攻击")
        } != nil)
        XCTAssertTrue(findSeed { rollSeed in
            var rng = SeededRNG(seed: rollSeed)
            let snap = BattleSnapshot(turn: 2, player: player, enemy: enemy, energy: 3)
            return LouseGreen.chooseMove(snapshot: snap, rng: &rng).intent.text.contains("卷曲")
        } != nil)
        
        XCTAssertTrue(findSeed { rollSeed in
            var rng = SeededRNG(seed: rollSeed)
            let snap = BattleSnapshot(turn: 2, player: player, enemy: enemy, energy: 3)
            return LouseRed.chooseMove(snapshot: snap, rng: &rng).intent.text.contains("攻击")
        } != nil)
        XCTAssertTrue(findSeed { rollSeed in
            var rng = SeededRNG(seed: rollSeed)
            let snap = BattleSnapshot(turn: 2, player: player, enemy: enemy, energy: 3)
            return LouseRed.chooseMove(snapshot: snap, rng: &rng).intent.text.contains("卷曲")
        } != nil)
        
        // Slime: attack or smear
        XCTAssertTrue(findSeed { rollSeed in
            var rng = SeededRNG(seed: rollSeed)
            let snap = BattleSnapshot(turn: 2, player: player, enemy: enemy, energy: 3)
            return SlimeMediumAcid.chooseMove(snapshot: snap, rng: &rng).intent.text.contains("攻击 10")
        } != nil)
        XCTAssertTrue(findSeed { rollSeed in
            var rng = SeededRNG(seed: rollSeed)
            let snap = BattleSnapshot(turn: 2, player: player, enemy: enemy, energy: 3)
            return SlimeMediumAcid.chooseMove(snapshot: snap, rng: &rng).intent.text.contains("涂抹")
        } != nil)
    }
    
    private func findSeed(_ predicate: (UInt64) -> Bool, max: UInt64 = 5000) -> UInt64? {
        for seed in 0..<max {
            if predicate(seed) { return seed }
        }
        return nil
    }
}


