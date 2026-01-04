import XCTest

/// GameCLI 帮助界面的黑盒「UI」测试
///
/// 目的：
/// - 覆盖战斗界面中 `h/help` 分支（showHelp + readLine 等待返回）
/// - 防止未来修改输入处理导致帮助页无法打开/无法返回（CI 卡死风险）
final class GameCLIHelpUITests: XCTestCase {
    /// 进入战斗后按 `h` 打开帮助，再返回并退出，stdout 应包含“游戏帮助”。
    func testBattleHelp_canOpenAndReturn() throws {
        let tmp = try TemporaryDirectory()
        defer { tmp.cleanup() }
        
        let result = try CLIRunner.runGameCLI(
            arguments: ["--seed", "1"],
            // 新冒险 → 起点 → 第一战斗 → h 帮助 → Enter 返回 → q 退出战斗 → 冒险结果 Enter → 主菜单退出
            stdin: "1\n1\n1\nh\n\nq\n\n3\n",
            environment: [
                "SALU_DATA_DIR": tmp.url.path,
                "SALU_TEST_MODE": "1"
            ],
            timeout: 10
        )
        
        XCTAssertEqual(result.exitCode, 0)
        
        let output = result.stdout.strippingANSICodes()
        XCTAssertTrue(output.contains("游戏帮助"), "期望能打开帮助界面（stdout）")
    }
}


