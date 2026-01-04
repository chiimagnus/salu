import Foundation
import GameCore
import XCTest

/// GameCLI 奖励系统（P1）黑盒「UI」测试
///
/// 目的：
/// - 验证战斗胜利后确实进入奖励界面（RewardScreen 接入没有断）
/// - 验证选择奖励后 deck 变化能被写入存档（RunSnapshot.deck 增长）
final class GameCLIRewardUITests: XCTestCase {
    /// 在测试模式下（`SALU_TEST_MODE=1`），第一场战斗应很快胜利并出现奖励界面；选择后 deck 从 13 → 14。
    func testRewardAfterBattle_addsCardToDeckAndPersistsToSave() throws {
        let tmp = try TemporaryDirectory()
        defer { tmp.cleanup() }
        
        let env: [String: String] = [
            "SALU_DATA_DIR": tmp.url.path,
            "SALU_TEST_MODE": "1"
        ]
        
        let result = try CLIRunner.runGameCLI(
            arguments: ["--seed", "123"],
            // 新冒险 → 起点 → 第一战斗 → 出牌 1（测试模式：快速胜利）→ 奖励选 1 → 回地图 q → 退出（有存档时 4）
            stdin: "1\n1\n1\n1\n1\nq\n4\n",
            environment: env,
            timeout: 10
        )
        
        XCTAssertEqual(result.exitCode, 0)
        
        let output = result.stdout.strippingANSICodes()
        XCTAssertTrue(output.contains("战斗奖励"), "期望出现“🎁 战斗奖励”界面（stdout）")
        
        // 存档应存在，且 deck 增长
        let saveURL = tmp.url.appendingPathComponent("run_save.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: saveURL.path), "期望生成 run_save.json")
        
        let data = try Data(contentsOf: saveURL)
        let snapshot = try JSONDecoder().decode(RunSnapshot.self, from: data)
        XCTAssertEqual(snapshot.deck.count, 14, "选择奖励后 deck 应从 13 增加到 14")
    }
}


