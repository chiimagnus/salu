import Foundation
import GameCore

/// 测试模式开关（仅用于 XCTest 的 CLI 黑盒测试）
///
/// - Note: 通过环境变量 `SALU_TEST_MODE=1` 启用。
/// - 目的：让 UI 测试更快、更稳定（例如把战斗压缩为“极低 HP 敌人 + 极小牌组”）。
enum TestMode {
    private static let envKey = "SALU_TEST_MODE"
    private static let mapKey = "SALU_TEST_MAP"
    
    static var isEnabled: Bool {
        ProcessInfo.processInfo.environment[envKey] == "1"
    }
    
    static var useTestMap: Bool {
        testMapKind != nil
    }
    
    private static var testMapKind: String? {
        guard let raw = ProcessInfo.processInfo.environment[mapKey] else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != "0" else { return nil }
        return trimmed
    }
    
    /// 在测试模式下，返回一个极小且稳定的战斗牌组，避免 UI 测试跑很久或出现概率性失败。
    static func battleDeck(from runDeck: [Card]) -> [Card] {
        guard isEnabled else { return runDeck }
        return [Card(id: "strike_test_1", cardId: "strike")]
    }
    
    /// 在测试模式下生成一张极小地图（起点 → 精英 → Boss）
    static func testRunState(seed: UInt64) -> RunState {
        let player = createDefaultPlayer()
        let deck = createStarterDeck()
        
        var relicManager = RelicManager()
        relicManager.add("burning_blood")

        let kind = testMapKind ?? "1"
        let map: [MapNode]
        switch kind {
        case "1", "mini":
            // 起点 → 精英 → Boss（原有默认）
            map = [
                MapNode(
                    id: "0_0",
                    row: 0,
                    column: 0,
                    roomType: .start,
                    connections: ["1_0"],
                    isAccessible: true
                ),
                MapNode(
                    id: "1_0",
                    row: 1,
                    column: 0,
                    roomType: .elite,
                    connections: ["2_0"]
                ),
                MapNode(
                    id: "2_0",
                    row: 2,
                    column: 0,
                    roomType: .boss
                )
            ]
            
        case "shop":
            // 起点 → 商店 → Boss（用于 P2 UI 测试）
            map = [
                MapNode(
                    id: "0_0",
                    row: 0,
                    column: 0,
                    roomType: .start,
                    connections: ["1_0"],
                    isAccessible: true
                ),
                MapNode(
                    id: "1_0",
                    row: 1,
                    column: 0,
                    roomType: .shop,
                    connections: ["2_0"]
                ),
                MapNode(
                    id: "2_0",
                    row: 2,
                    column: 0,
                    roomType: .boss
                )
            ]
            
        case "rest":
            // 起点 → 休息点 → Boss（用于 P3 UI 测试）
            map = [
                MapNode(
                    id: "0_0",
                    row: 0,
                    column: 0,
                    roomType: .start,
                    connections: ["1_0"],
                    isAccessible: true
                ),
                MapNode(
                    id: "1_0",
                    row: 1,
                    column: 0,
                    roomType: .rest,
                    connections: ["2_0"]
                ),
                MapNode(
                    id: "2_0",
                    row: 2,
                    column: 0,
                    roomType: .boss
                )
            ]

        case "event":
            // 起点 → 事件 → Boss（用于 P5 UI 测试）
            map = [
                MapNode(
                    id: "0_0",
                    row: 0,
                    column: 0,
                    roomType: .start,
                    connections: ["1_0"],
                    isAccessible: true
                ),
                MapNode(
                    id: "1_0",
                    row: 1,
                    column: 0,
                    roomType: .event,
                    connections: ["2_0"]
                ),
                MapNode(
                    id: "2_0",
                    row: 2,
                    column: 0,
                    roomType: .boss
                )
            ]
            
        default:
            // fallback：沿用 mini
            map = [
                MapNode(
                    id: "0_0",
                    row: 0,
                    column: 0,
                    roomType: .start,
                    connections: ["1_0"],
                    isAccessible: true
                ),
                MapNode(
                    id: "1_0",
                    row: 1,
                    column: 0,
                    roomType: .elite,
                    connections: ["2_0"]
                ),
                MapNode(
                    id: "2_0",
                    row: 2,
                    column: 0,
                    roomType: .boss
                )
            ]
        }
        
        let gold: Int
        switch kind {
        case "shop":
            // UI 测试时提供足够金币，避免因未来卡池变化导致购买失败
            gold = 999
        default:
            gold = RunState.startingGold
        }
        
        return RunState(
            player: player,
            deck: deck,
            gold: gold,
            relicManager: relicManager,
            map: map,
            seed: seed
        )
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
