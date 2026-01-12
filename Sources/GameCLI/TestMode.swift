import Foundation
import GameCore

/// 测试模式开关（仅用于 XCTest 的 CLI 黑盒测试）
///
/// - Note: 通过环境变量 `SALU_TEST_MODE=1` 启用。
/// - 目的：让 UI 测试更快、更稳定（例如把战斗压缩为“极低 HP 敌人 + 极小牌组”）。
enum TestMode {
    private static let envKey = "SALU_TEST_MODE"
    private static let mapKey = "SALU_TEST_MAP"
    private static let maxFloorKey = "SALU_TEST_MAX_FLOOR"
    private static let battleDeckKey = "SALU_TEST_BATTLE_DECK"
    private static let enemyHPKey = "SALU_TEST_ENEMY_HP"
    
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
    
    /// 测试模式下可覆盖最大楼层（Act 数），用于验证 Act 推进链路。
    /// - Note: 默认为 1，避免现有 UI 测试被 Act2 拉长。
    private static var testMaxFloor: Int {
        guard let raw = ProcessInfo.processInfo.environment[maxFloorKey] else { return 1 }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let n = Int(trimmed), n > 0 else { return 1 }
        return n
    }
    
    /// 在测试模式下，返回一个极小且稳定的战斗牌组，避免 UI 测试跑很久或出现概率性失败。
    static func battleDeck(from runDeck: [Card]) -> [Card] {
        guard isEnabled else { return runDeck }
        
        // 允许通过环境变量覆盖测试战斗牌组，便于手动验收特定机制（例如占卜家序列）。
        // - 默认：minimal（仅 1 张打击）
        // - run：使用当前冒险牌组（更贴近真实流程，但可能导致 UI 测试不稳定）
        // - seer：注入一套覆盖“预知/回溯/改写/清理疯狂”的占卜家测试牌组
        let kind = (ProcessInfo.processInfo.environment[battleDeckKey] ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        
        switch kind {
        case "run":
            return runDeck
        case "seer":
            return seerTestBattleDeck()
        case "seer_p7":
            return seerP7TestBattleDeck()
        default:
            return [Card(id: "strike_test_1", cardId: "strike")]
        }
    }

    private static func seerTestBattleDeck() -> [Card] {
        [
            // 覆盖：预知（SpiritSight / TruthWhisper）
            Card(id: "seer_test_spirit_sight_1", cardId: "spirit_sight"),
            Card(id: "seer_test_spirit_sight_2", cardId: "spirit_sight"),
            Card(id: "seer_test_truth_whisper_1", cardId: "truth_whisper"),
            Card(id: "seer_test_truth_whisper_2", cardId: "truth_whisper"),

            // 覆盖：清除疯狂（Meditation）
            Card(id: "seer_test_meditation_1", cardId: "meditation"),
            Card(id: "seer_test_meditation_2", cardId: "meditation"),

            // 覆盖：改写敌人意图（FateRewrite）
            Card(id: "seer_test_fate_rewrite_1", cardId: "fate_rewrite"),
            Card(id: "seer_test_fate_rewrite_2", cardId: "fate_rewrite"),

            // 覆盖：回溯（TimeShard）
            Card(id: "seer_test_time_shard_1", cardId: "time_shard"),
            Card(id: "seer_test_time_shard_2", cardId: "time_shard"),
        ]
    }

    private static func seerP7TestBattleDeck() -> [Card] {
        [
            // P7：序列共鸣（能力）
            Card(id: "seer_p7_sequence_resonance_1", cardId: "sequence_resonance"),

            // P7：预言回响（伤害×本回合预知次数）
            Card(id: "seer_p7_prophecy_echo_1", cardId: "prophecy_echo"),

            // P7：净化仪式（清除所有疯狂）
            Card(id: "seer_p7_purification_ritual_1", cardId: "purification_ritual"),

            // P1：预知（用于触发序列共鸣/预言回响）
            Card(id: "seer_p7_spirit_sight_1", cardId: "spirit_sight"),
            Card(id: "seer_p7_spirit_sight_2", cardId: "spirit_sight"),
            Card(id: "seer_p7_truth_whisper_1", cardId: "truth_whisper"),

            // P1：清除疯狂（对照用）
            Card(id: "seer_p7_meditation_1", cardId: "meditation"),

            // P1：改写（用于 Boss 机制验收）
            Card(id: "seer_p7_fate_rewrite_1", cardId: "fate_rewrite"),
        ]
    }

    /// 测试模式下使用的固定小地图（起点 → 1 个房间 → Boss）。
    ///
    /// - Note: 用于 Act 推进时复用，避免进入下一幕后退回 15 层分支大地图。
    static func testMapNodes() -> [MapNode] {
        let kind = testMapKind ?? "1"
        switch kind {
        case "1", "mini":
            // 起点 → 精英 → Boss（原有默认）
            return [
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

        case "battle":
            // 起点 → 普通战斗 → Boss（用于多敌人/目标选择 UI 测试）
            return [
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
                    roomType: .battle,
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
            return [
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
            return [
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
            return [
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
            return [
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
    }
    
    /// 在测试模式下生成一张极小地图（起点 → 精英 → Boss）
    static func testRunState(seed: UInt64) -> RunState {
        let player = createDefaultPlayer()
        let deck = createStarterDeck()
        
        var relicManager = RelicManager()
        relicManager.add("burning_blood")

        let kind = testMapKind ?? "1"
        let map = testMapNodes()
        
        let gold: Int
        switch kind {
        case "shop":
            // UI 测试时提供足够金币，避免因未来卡池变化导致购买失败
            gold = 999
        default:
            gold = RunState.startingGold
        }
        
        let maxFloor = testMaxFloor
        
        return RunState(
            player: player,
            deck: deck,
            gold: gold,
            relicManager: relicManager,
            map: map,
            seed: seed,
            floor: 1,
            maxFloor: maxFloor
        )
    }
    
    /// 创建敌人（测试模式下压缩 HP，提升 UI 测试稳定性）
    static func createEnemy(enemyId: EnemyID, instanceIndex: Int, rng: inout SeededRNG) -> Entity {
        guard isEnabled else {
            return GameCore.createEnemy(enemyId: enemyId, instanceIndex: instanceIndex, rng: &rng)
        }

        // 允许在测试模式下保留真实 HP（用于手动验收 Boss 阶段机制等）。
        if let raw = ProcessInfo.processInfo.environment[enemyHPKey] {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if trimmed == "normal" || trimmed == "keep" {
                return GameCore.createEnemy(enemyId: enemyId, instanceIndex: instanceIndex, rng: &rng)
            }
            if let hp = Int(trimmed), hp > 0 {
                let def = EnemyRegistry.require(enemyId)
                return Entity(id: "\(enemyId.rawValue)#\(instanceIndex)", name: def.name, maxHP: hp, enemyId: enemyId)
            }
        }
        
        let def = EnemyRegistry.require(enemyId)
        return Entity(id: "\(enemyId.rawValue)#\(instanceIndex)", name: def.name, maxHP: 1, enemyId: enemyId)
    }
}
