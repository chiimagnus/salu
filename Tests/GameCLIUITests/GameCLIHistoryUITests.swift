import Foundation
import GameCore
import XCTest

/// GameCLI 战绩写入（battle_history.json）的黑盒「UI」测试
///
/// 目的：
/// - 验证 `BattleRoomHandler -> HistoryService -> FileBattleHistoryStore` 的真实落盘链路可用
/// - 断言以“文件副作用 + JSON 可解码 + 关键字段”为主，避免仅靠 stdout 关键字假绿
final class GameCLIHistoryUITests: XCTestCase {
    /// 跑一场（测试模式下的）快速战斗后，应写入 battle_history.json，且记录可被 JSONDecoder 解码。
    func testBattleHistory_isWrittenAndDecodable() throws {
        let tmp = try TemporaryDirectory()
        defer { tmp.cleanup() }
        
        let env: [String: String] = [
            "SALU_DATA_DIR": tmp.url.path,
            "SALU_TEST_MODE": "1"
        ]
        
        _ = try CLIRunner.runGameCLI(
            arguments: ["--seed", "42"],
            // 新冒险 → 起点 → 第一战斗 → 出牌 1（胜利）→ 奖励跳过 0 → 回地图 q → 退出 4
            stdin: "1\n1\n1\n1\n0\nq\n4\n",
            environment: env,
            timeout: 10
        )
        
        let historyURL = tmp.url.appendingPathComponent("battle_history.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: historyURL.path), "期望生成 battle_history.json")
        
        let data = try Data(contentsOf: historyURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let records = try decoder.decode([BattleRecord].self, from: data)
        XCTAssertGreaterThanOrEqual(records.count, 1, "至少应记录 1 场战斗")
        
        // 在测试模式下：战斗应极短，至少应有出牌统计。
        XCTAssertGreaterThanOrEqual(records.last?.cardsPlayed ?? 0, 1)
    }
}


