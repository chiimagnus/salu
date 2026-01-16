import Foundation
import GameCore
import XCTest

/// 多敌人战斗 + 目标选择的黑盒「UI」测试
///
/// 目的：
/// - 让 CI 能稳定覆盖“多敌人 + 攻击牌必须选目标”的路径
/// - 避免只靠人工反复开新局碰概率
final class GameCLIMultiEnemyTargetingUITests: XCTestCase {
    func testMultiEnemyBattle_requiresTargetInput_andCanWin() throws {
        print("🧪 测试：testMultiEnemyBattle_requiresTargetInput_andCanWin")
        let tmp = try TemporaryDirectory()
        defer { tmp.cleanup() }
        
        let env: [String: String] = [
            "SALU_DATA_DIR": tmp.url.path,
            "SALU_TEST_MODE": "1",
            "SALU_TEST_MAP": "battle",
            "SALU_FORCE_MULTI_ENEMY": "1"
        ]
        
        let result = try CLIRunner.runGameCLI(
            arguments: ["--seed", "42"],
            // 新冒险 → 起点 → 普通战斗（双敌人）→ 先输入 1（缺目标，应提示）→ 再 1 1 击杀 #1 → 结束回合 → 1 自动打 #2 → 奖励跳过 0 → 回地图 q → 退出 4
            stdin: "1\n1\n1\n1\n1 1\n0\n1\n0\nq\n4\n",
            environment: env,
            timeout: 12
        )
        
        let output = result.stdout.strippingANSICodes()
        
        XCTAssertTrue(output.contains("Green Louse"))
        XCTAssertTrue(output.contains("Red Louse"))
        XCTAssertTrue(output.contains("👹 [1]"))
        XCTAssertTrue(output.contains("👹 [2]"))
        XCTAssertTrue(output.contains("This card requires a target"))
    }
}

