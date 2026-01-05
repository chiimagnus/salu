import Foundation
import GameCore
import XCTest

/// GameCLI 遗物奖励黑盒「UI」测试
///
/// 目的：
/// - 验证精英战斗掉落遗物并写入存档
/// - 验证继续冒险后遗物效果仍然生效
final class GameCLIRelicRewardUITests: XCTestCase {
    func testRelicReward_persistsAndKeepsEffectAfterContinue() throws {
        print("🧪 测试：testRelicReward_persistsAndKeepsEffectAfterContinue")
        let tmp = try TemporaryDirectory()
        defer { tmp.cleanup() }
        
        let env: [String: String] = [
            "SALU_DATA_DIR": tmp.url.path,
            "SALU_TEST_MODE": "1",
            "SALU_TEST_MAP": "1"
        ]
        
        let firstRun = try CLIRunner.runGameCLI(
            arguments: ["--seed", "123"],
            // 新冒险 → 起点 → 精英战斗 → 出牌 1（测试模式：快速胜利）
            // → 获得遗物 → 选择卡牌奖励 → 回地图 q → 退出（有存档时 4）
            stdin: "1\n1\n1\n1\n1\n1\nq\n4\n",
            environment: env,
            timeout: 12
        )
        
        XCTAssertEqual(firstRun.exitCode, 0)
        
        let saveURL = tmp.url.appendingPathComponent("run_save.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: saveURL.path), "期望生成 run_save.json")
        
        let data = try Data(contentsOf: saveURL)
        let snapshot = try JSONDecoder().decode(RunSnapshot.self, from: data)
        
        let earnedRelic = snapshot.relicIds.first { $0 != "burning_blood" }
        XCTAssertNotNil(earnedRelic, "期望存档中包含精英掉落的遗物")
        
        let secondRun = try CLIRunner.runGameCLI(
            arguments: ["--seed", "123"],
            // 继续冒险 → 进入 Boss → 出牌 1 → 跳过遗物 → 回主菜单 → 退出
            stdin: "1\n1\n1\n0\n\n4\n",
            environment: env,
            timeout: 12
        )
        
        XCTAssertEqual(secondRun.exitCode, 0)
        
        let output = secondRun.stdout.strippingANSICodes()
        if earnedRelic == "vajra" {
            XCTAssertTrue(output.contains("💪力量+1"), "期望继续冒险后力量加成依旧生效")
        } else if earnedRelic == "lantern" {
            XCTAssertTrue(output.contains("4/3"), "期望继续冒险后额外能量依旧生效")
        } else {
            XCTFail("未识别的遗物掉落：\(earnedRelic ?? "nil")")
        }
    }
}
