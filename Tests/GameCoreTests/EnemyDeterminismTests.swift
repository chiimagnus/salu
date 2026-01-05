import XCTest
@testable import GameCore

/// 敌人系统确定性单元测试
///
/// 目的：
/// - 验证同一 seed 下，EnemyPool/EnemyDefinition 的随机决策可复现
/// - 为后续扩展敌人/精英/Boss 提供“可复现性”回归保护
final class EnemyDeterminismTests: XCTestCase {
    /// Act1EnemyPool 的随机选择必须可复现（同 seed → 同 enemyId）。
    func testAct1EnemyPool_randomWeak_isDeterministic() {
        print("🧪 测试：testAct1EnemyPool_randomWeak_isDeterministic")
        var rng1 = SeededRNG(seed: 100)
        var rng2 = SeededRNG(seed: 100)
        
        let a = Act1EnemyPool.randomWeak(rng: &rng1)
        let b = Act1EnemyPool.randomWeak(rng: &rng2)
        
        XCTAssertEqual(a, b)
    }
    
    /// 敌人 AI（chooseMove）必须在同一 seed + 同一 snapshot 下产生相同的 EnemyMove（可复现性）。
    func testJawWorm_chooseMove_isDeterministic_givenSameSeedAndSnapshot() {
        print("🧪 测试：testJawWorm_chooseMove_isDeterministic_givenSameSeedAndSnapshot")
        let snapshot = BattleSnapshot(
            turn: 2,
            player: Entity(id: "p", name: "玩家", maxHP: 10),
            enemy: Entity(id: "e", name: "下颚虫", maxHP: 10, enemyId: "jaw_worm"),
            energy: 3
        )
        
        var rng1 = SeededRNG(seed: 999)
        var rng2 = SeededRNG(seed: 999)
        
        let a = JawWorm.chooseMove(snapshot: snapshot, rng: &rng1)
        let b = JawWorm.chooseMove(snapshot: snapshot, rng: &rng2)
        
        XCTAssertEqual(a, b)
    }
}


