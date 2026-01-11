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

    func testAct2EnemyPool_randomPickWithinPools() {
        print("🧪 测试：testAct2EnemyPool_randomPickWithinPools")
        var rng = SeededRNG(seed: 2)
        let w = Act2EnemyPool.randomWeak(rng: &rng)
        XCTAssertTrue(Act2EnemyPool.weak.contains(w))
        
        let m = Act2EnemyPool.randomMedium(rng: &rng)
        XCTAssertTrue(Act2EnemyPool.medium.contains(m))
    }
    
    func testCreateEnemy_hpRange() {
        print("🧪 测试：testCreateEnemy_hpRange")
        var rng = SeededRNG(seed: 123)
        let enemy = createEnemy(enemyId: "jaw_worm", instanceIndex: 0, rng: &rng)
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
            let snap = BattleSnapshot(turn: 1, player: player, enemies: [enemy], energy: 3)
            return JawWorm.chooseMove(selfIndex: 0, snapshot: snap, rng: &rng).intent.text.contains("攻击")
        } != nil)
        
        XCTAssertTrue(findSeed { rollSeed in
            var rng = SeededRNG(seed: rollSeed)
            let snap = BattleSnapshot(turn: 1, player: player, enemies: [enemy], energy: 3)
            return JawWorm.chooseMove(selfIndex: 0, snapshot: snap, rng: &rng).intent.text.contains("力量")
        } != nil)
        
        // JawWorm later turns: three options (attack 11 / strength / pounce 7)
        XCTAssertTrue(findSeed { rollSeed in
            var rng = SeededRNG(seed: rollSeed)
            let snap = BattleSnapshot(turn: 2, player: player, enemies: [enemy], energy: 3)
            return JawWorm.chooseMove(selfIndex: 0, snapshot: snap, rng: &rng).intent.text.contains("攻击 11")
        } != nil)
        
        XCTAssertTrue(findSeed { rollSeed in
            var rng = SeededRNG(seed: rollSeed)
            let snap = BattleSnapshot(turn: 2, player: player, enemies: [enemy], energy: 3)
            return JawWorm.chooseMove(selfIndex: 0, snapshot: snap, rng: &rng).intent.text.contains("力量")
        } != nil)
        
        XCTAssertTrue(findSeed { rollSeed in
            var rng = SeededRNG(seed: rollSeed)
            let snap = BattleSnapshot(turn: 2, player: player, enemies: [enemy], energy: 3)
            return JawWorm.chooseMove(selfIndex: 0, snapshot: snap, rng: &rng).intent.text.contains("猛扑")
        } != nil)
        
        // Cultist: turn 1 strength, later attack
        do {
            var rng = SeededRNG(seed: 1)
            let snap1 = BattleSnapshot(turn: 1, player: player, enemies: [enemy], energy: 3)
            XCTAssertTrue(Cultist.chooseMove(selfIndex: 0, snapshot: snap1, rng: &rng).intent.text.contains("力量"))
            let snap2 = BattleSnapshot(turn: 2, player: player, enemies: [enemy], energy: 3)
            XCTAssertTrue(Cultist.chooseMove(selfIndex: 0, snapshot: snap2, rng: &rng).intent.text.contains("攻击"))
        }
        
        // Louse (green/red): attack or curl
        XCTAssertTrue(findSeed { rollSeed in
            var rng = SeededRNG(seed: rollSeed)
            let snap = BattleSnapshot(turn: 2, player: player, enemies: [enemy], energy: 3)
            return LouseGreen.chooseMove(selfIndex: 0, snapshot: snap, rng: &rng).intent.text.contains("攻击")
        } != nil)
        XCTAssertTrue(findSeed { rollSeed in
            var rng = SeededRNG(seed: rollSeed)
            let snap = BattleSnapshot(turn: 2, player: player, enemies: [enemy], energy: 3)
            return LouseGreen.chooseMove(selfIndex: 0, snapshot: snap, rng: &rng).intent.text.contains("卷曲")
        } != nil)
        
        XCTAssertTrue(findSeed { rollSeed in
            var rng = SeededRNG(seed: rollSeed)
            let snap = BattleSnapshot(turn: 2, player: player, enemies: [enemy], energy: 3)
            return LouseRed.chooseMove(selfIndex: 0, snapshot: snap, rng: &rng).intent.text.contains("攻击")
        } != nil)
        XCTAssertTrue(findSeed { rollSeed in
            var rng = SeededRNG(seed: rollSeed)
            let snap = BattleSnapshot(turn: 2, player: player, enemies: [enemy], energy: 3)
            return LouseRed.chooseMove(selfIndex: 0, snapshot: snap, rng: &rng).intent.text.contains("卷曲")
        } != nil)
        
        // Slime: attack or smear
        XCTAssertTrue(findSeed { rollSeed in
            var rng = SeededRNG(seed: rollSeed)
            let snap = BattleSnapshot(turn: 2, player: player, enemies: [enemy], energy: 3)
            return SlimeMediumAcid.chooseMove(selfIndex: 0, snapshot: snap, rng: &rng).intent.text.contains("攻击 10")
        } != nil)
        XCTAssertTrue(findSeed { rollSeed in
            var rng = SeededRNG(seed: rollSeed)
            let snap = BattleSnapshot(turn: 2, player: player, enemies: [enemy], energy: 3)
            return SlimeMediumAcid.chooseMove(selfIndex: 0, snapshot: snap, rng: &rng).intent.text.contains("涂抹")
        } != nil)
    }
    
    func testAct2Enemies_chooseMove_coversBranches() {
        print("🧪 测试：testAct2Enemies_chooseMove_coversBranches")
        let player = Entity(id: "player", name: "玩家", maxHP: 80)
        let enemy = Entity(id: "enemy", name: "敌人", maxHP: 40, enemyId: "shadow_stalker")
        
        // ShadowStalker turn 1: always weak
        do {
            var rng = SeededRNG(seed: 1)
            let snap1 = BattleSnapshot(turn: 1, player: player, enemies: [enemy], energy: 3)
            XCTAssertTrue(ShadowStalker.chooseMove(selfIndex: 0, snapshot: snap1, rng: &rng).intent.text.contains("虚弱"))
        }
        
        // ShadowStalker later: attack or block
        XCTAssertTrue(findSeed { rollSeed in
            var rng = SeededRNG(seed: rollSeed)
            let snap = BattleSnapshot(turn: 2, player: player, enemies: [enemy], energy: 3)
            return ShadowStalker.chooseMove(selfIndex: 0, snapshot: snap, rng: &rng).intent.text.contains("刺杀")
        } != nil)
        XCTAssertTrue(findSeed { rollSeed in
            var rng = SeededRNG(seed: rollSeed)
            let snap = BattleSnapshot(turn: 2, player: player, enemies: [enemy], energy: 3)
            return ShadowStalker.chooseMove(selfIndex: 0, snapshot: snap, rng: &rng).intent.text.contains("格挡")
        } != nil)
        
        // ClockworkSentinel: three branches
        XCTAssertTrue(findSeed { rollSeed in
            var rng = SeededRNG(seed: rollSeed)
            let snap = BattleSnapshot(turn: 2, player: player, enemies: [enemy], energy: 3)
            return ClockworkSentinel.chooseMove(selfIndex: 0, snapshot: snap, rng: &rng).intent.text.contains("连射")
        } != nil)
        XCTAssertTrue(findSeed { rollSeed in
            var rng = SeededRNG(seed: rollSeed)
            let snap = BattleSnapshot(turn: 2, player: player, enemies: [enemy], energy: 3)
            return ClockworkSentinel.chooseMove(selfIndex: 0, snapshot: snap, rng: &rng).intent.text.contains("装甲")
        } != nil)
        XCTAssertTrue(findSeed { rollSeed in
            var rng = SeededRNG(seed: rollSeed)
            let snap = BattleSnapshot(turn: 2, player: player, enemies: [enemy], energy: 3)
            return ClockworkSentinel.chooseMove(selfIndex: 0, snapshot: snap, rng: &rng).intent.text.contains("力量")
        } != nil)
        
        // RuneGuardian: deterministic cycle after turn 1
        do {
            var rng = SeededRNG(seed: 1)
            let snap1 = BattleSnapshot(turn: 1, player: player, enemies: [enemy], energy: 3)
            XCTAssertTrue(RuneGuardian.chooseMove(selfIndex: 0, snapshot: snap1, rng: &rng).intent.text.contains("易伤"))
            
            let snap2 = BattleSnapshot(turn: 2, player: player, enemies: [enemy], energy: 3)
            XCTAssertTrue(RuneGuardian.chooseMove(selfIndex: 0, snapshot: snap2, rng: &rng).intent.text.contains("重击"))
            
            let snap3 = BattleSnapshot(turn: 3, player: player, enemies: [enemy], energy: 3)
            XCTAssertTrue(RuneGuardian.chooseMove(selfIndex: 0, snapshot: snap3, rng: &rng).intent.text.contains("护盾") || RuneGuardian.chooseMove(selfIndex: 0, snapshot: snap3, rng: &rng).intent.text.contains("格挡"))
        }
        
        // Cipher（赛弗）: 3 阶段 Boss（P2 替换 ChronoWatcher）
        // 阶段由 HP 百分比决定，测试阶段 1（HP > 60%）的循环
        do {
            var rng = SeededRNG(seed: 1)
            let cipherEnemy = Entity(id: "cipher", name: "赛弗", maxHP: 100, enemyId: "cipher")
            let s1 = BattleSnapshot(turn: 1, player: player, enemies: [cipherEnemy], energy: 3)
            XCTAssertTrue(Cipher.chooseMove(selfIndex: 0, snapshot: s1, rng: &rng).intent.text.contains("试探"))
            let s2 = BattleSnapshot(turn: 2, player: player, enemies: [cipherEnemy], energy: 3)
            XCTAssertTrue(Cipher.chooseMove(selfIndex: 0, snapshot: s2, rng: &rng).intent.text.contains("预判"))
            let s3 = BattleSnapshot(turn: 3, player: player, enemies: [cipherEnemy], energy: 3)
            XCTAssertTrue(Cipher.chooseMove(selfIndex: 0, snapshot: s3, rng: &rng).intent.text.contains("预知反制"))
        }
    }
    
    func testAct1EliteAndBoss_chooseMove_coversBranchesAndCycles() {
        print("🧪 测试：testAct1EliteAndBoss_chooseMove_coversBranchesAndCycles")
        let player = Entity(id: "player", name: "玩家", maxHP: 80)
        let enemy = Entity(id: "enemy", name: "敌人", maxHP: 40, enemyId: "stone_sentinel")
        
        // StoneSentinel turn 1: always block
        do {
            var rng = SeededRNG(seed: 1)
            let snap1 = BattleSnapshot(turn: 1, player: player, enemies: [enemy], energy: 3)
            XCTAssertTrue(StoneSentinel.chooseMove(selfIndex: 0, snapshot: snap1, rng: &rng).intent.text.contains("格挡"))
        }
        
        // StoneSentinel later: three branches
        XCTAssertTrue(findSeed { rollSeed in
            var rng = SeededRNG(seed: rollSeed)
            let snap = BattleSnapshot(turn: 2, player: player, enemies: [enemy], energy: 3)
            return StoneSentinel.chooseMove(selfIndex: 0, snapshot: snap, rng: &rng).intent.text.contains("重击")
        } != nil)
        XCTAssertTrue(findSeed { rollSeed in
            var rng = SeededRNG(seed: rollSeed)
            let snap = BattleSnapshot(turn: 2, player: player, enemies: [enemy], energy: 3)
            return StoneSentinel.chooseMove(selfIndex: 0, snapshot: snap, rng: &rng).intent.text.contains("连斩")
        } != nil)
        XCTAssertTrue(findSeed { rollSeed in
            var rng = SeededRNG(seed: rollSeed)
            let snap = BattleSnapshot(turn: 2, player: player, enemies: [enemy], energy: 3)
            return StoneSentinel.chooseMove(selfIndex: 0, snapshot: snap, rng: &rng).intent.text.contains("固守")
        } != nil)
        
        // ToxicColossus: deterministic 4-turn loop
        do {
            var rng = SeededRNG(seed: 1)
            let eBoss = Entity(id: "boss", name: "Boss", maxHP: 100, enemyId: "toxic_colossus")
            
            let t1 = BattleSnapshot(turn: 1, player: player, enemies: [eBoss], energy: 3)
            let m1 = ToxicColossus.chooseMove(selfIndex: 0, snapshot: t1, rng: &rng)
            XCTAssertTrue(m1.intent.text.contains("毒雾"))
            
            let t2 = BattleSnapshot(turn: 2, player: player, enemies: [eBoss], energy: 3)
            let m2 = ToxicColossus.chooseMove(selfIndex: 0, snapshot: t2, rng: &rng)
            XCTAssertTrue(m2.intent.text.contains("践踏"))
            
            let t3 = BattleSnapshot(turn: 3, player: player, enemies: [eBoss], energy: 3)
            let m3 = ToxicColossus.chooseMove(selfIndex: 0, snapshot: t3, rng: &rng)
            XCTAssertTrue(m3.intent.text.contains("腐蚀打击"))
            
            let t4 = BattleSnapshot(turn: 4, player: player, enemies: [eBoss], energy: 3)
            let m4 = ToxicColossus.chooseMove(selfIndex: 0, snapshot: t4, rng: &rng)
            XCTAssertTrue(m4.intent.text.contains("连击"))
        }
    }
    
    private func findSeed(_ predicate: (UInt64) -> Bool, max: UInt64 = 5000) -> UInt64? {
        for seed in 0..<max {
            if predicate(seed) { return seed }
        }
        return nil
    }
}


