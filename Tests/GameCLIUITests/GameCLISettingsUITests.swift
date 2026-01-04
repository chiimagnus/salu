import XCTest

/// GameCLI 设置菜单的黑盒「UI」测试
///
/// 目的：
/// - 覆盖 `mainMenuLoop -> settingsMenuLoop` 的输入分支
/// - 覆盖“查看统计 / 清除历史”的交互路径，防止菜单改动导致入口损坏
final class GameCLISettingsUITests: XCTestCase {
    /// 从主菜单进入设置，查看统计并清除历史（yes 分支），最终返回主菜单并退出。
    func testSettingsMenu_statsAndClearHistory_canNavigate() throws {
        let tmp = try TemporaryDirectory()
        defer { tmp.cleanup() }
        
        let result = try CLIRunner.runGameCLI(
            arguments: ["--seed", "1"],
            stdin: "2\n2\n\n3\nyes\n\n0\n3\n",
            environment: [
                "SALU_DATA_DIR": tmp.url.path,
                "SALU_TEST_MODE": "1"
            ],
            timeout: 8
        )
        
        XCTAssertEqual(result.exitCode, 0)
        
        let output = result.stdout.strippingANSICodes()
        XCTAssertTrue(output.contains("设置菜单"), "期望进入设置菜单（stdout）")
        XCTAssertTrue(output.contains("战绩统计"), "期望能打开统计界面（stdout）")
        XCTAssertTrue(output.contains("历史记录已清除"), "期望清除历史记录的提示出现（stdout）")
    }
}


