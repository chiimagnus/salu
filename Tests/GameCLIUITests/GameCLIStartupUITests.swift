import XCTest

/// GameCLI 启动/主菜单的黑盒「UI」测试
///
/// 目的：
/// - 验证可执行文件能启动并正常退出（避免 CI 假绿：只编译通过但运行即挂）
/// - 验证主菜单关键文案存在（证明流程走到了 UI 层）
final class GameCLIStartupUITests: XCTestCase {
    /// 无存档时：主菜单应包含“开始冒险”，并且输入 `3` 可以正常退出。
    func testMainMenuBootAndExit_withoutSave() throws {
        let tmp = try TemporaryDirectory()
        defer { tmp.cleanup() }
        
        let result = try CLIRunner.runGameCLI(
            arguments: ["--seed", "1"],
            stdin: "3\n",
            environment: [
                "SALU_DATA_DIR": tmp.url.path
            ],
            timeout: 6
        )
        
        XCTAssertEqual(result.exitCode, 0)
        
        let output = result.stdout.strippingANSICodes()
        XCTAssertTrue(output.contains("杀戮尖塔"), "期望出现游戏标题/主菜单（stdout）")
        XCTAssertTrue(output.contains("开始冒险"), "期望出现无存档时的菜单项（stdout）")
    }
}


