import XCTest

/// 不开启 `SALU_TEST_MODE` 的 CLI smoke 测试
///
/// 目的：
/// - 在“真实参数/真实 HP 范围/真实起始牌组”下跑一条最短路径，验证不崩溃、不挂死。
/// - 不追求战斗胜利，也不做复杂断言；只做最低限度的可运行性保护。
final class GameCLISmokeNoTestModeUITests: XCTestCase {
    /// 新冒险 → 起点 → 进入战斗 → 直接 `q` 退出战斗（视为失败结束 run）→ 返回主菜单 → 退出。
    func testSmoke_realMode_enterBattleAndQuit_doesNotHang() throws {
        let tmp = try TemporaryDirectory()
        defer { tmp.cleanup() }
        
        let result = try CLIRunner.runGameCLI(
            arguments: ["--seed", "1"],
            stdin: "1\n1\n1\nq\n\n3\n",
            environment: [
                "SALU_DATA_DIR": tmp.url.path
            ],
            timeout: 12
        )
        
        XCTAssertEqual(result.exitCode, 0)
        
        let output = result.stdout.strippingANSICodes()
        XCTAssertTrue(output.contains("冒险失败") || output.contains("战斗"), "期望至少进入过 run/battle 相关界面（stdout）")
    }
}


