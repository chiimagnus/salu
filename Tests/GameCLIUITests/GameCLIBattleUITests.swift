import XCTest

/// GameCLI 战斗界面的黑盒「UI」测试
///
/// 目的：
/// - 验证从“新冒险 → 地图 → 战斗界面”链路可达（避免只测到 Map/菜单）
/// - 验证在战斗界面输入 `q` 能返回并结束流程（不挂死）
final class GameCLIBattleUITests: XCTestCase {
    /// 进入第一场战斗后退出，stdout 应出现敌人标识（👹）或意图字段。
    func testEnterBattleScreenAndQuit_doesNotHang() throws {
        let tmp = try TemporaryDirectory()
        defer { tmp.cleanup() }
        
        let result = try CLIRunner.runGameCLI(
            arguments: ["--seed", "1"],
            // 新冒险 → 起点 → 第一战斗节点 → 战斗界面 q 退出 → 冒险结果 Enter → 主菜单退出
            stdin: "1\n1\n1\nq\n\n3\n",
            environment: [
                "SALU_DATA_DIR": tmp.url.path
            ],
            timeout: 10
        )
        
        XCTAssertEqual(result.exitCode, 0)
        
        let output = result.stdout.strippingANSICodes()
        XCTAssertTrue(output.contains("👹") || output.contains("意图"), "期望出现战斗界面关键标识（stdout）")
    }
}


