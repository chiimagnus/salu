import Foundation
import GameCore

/// 测试模式开关（仅用于 XCTest 的 CLI 黑盒测试）
///
/// - Note: 通过环境变量 `SALU_TEST_MODE=1` 启用。
/// - 目的：让 UI 测试更快、更稳定（例如把战斗压缩为“极低 HP 敌人 + 极小牌组”）。
enum TestMode {
    private static let envKey = "SALU_TEST_MODE"
    
    static var isEnabled: Bool {
        ProcessInfo.processInfo.environment[envKey] == "1"
    }
    
    /// 在测试模式下，返回一个极小且稳定的战斗牌组，避免 UI 测试跑很久或出现概率性失败。
    static func battleDeck(from runDeck: [Card]) -> [Card] {
        guard isEnabled else { return runDeck }
        return [Card(id: "strike_test_1", cardId: "strike")]
    }
    
    /// 创建敌人（测试模式下压缩 HP，提升 UI 测试稳定性）
    static func createEnemy(enemyId: EnemyID, rng: inout SeededRNG) -> Entity {
        guard isEnabled else {
            return GameCore.createEnemy(enemyId: enemyId, rng: &rng)
        }
        
        let def = EnemyRegistry.require(enemyId)
        return Entity(id: enemyId.rawValue, name: def.name, maxHP: 1, enemyId: enemyId)
    }
}


