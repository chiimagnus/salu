import XCTest

/// 命令行参数分支的黑盒测试
///
/// 目的：
/// - 覆盖 `GameCLI.main()` 中 `--history` / `--stats` 的早退分支
/// - 避免未来修改参数解析导致这些入口损坏但主流程仍能跑（假绿）
final class GameCLIArgumentUITests: XCTestCase {
    /// `--history` 应打印历史界面标题并退出（不等待输入）。
    func testHistoryFlag_printsAndExits() throws {
        print("🧪 测试：testHistoryFlag_printsAndExits")
        let tmp = try TemporaryDirectory()
        defer { tmp.cleanup() }
        
        let result = try CLIRunner.runGameCLI(
            arguments: ["--history"],
            stdin: "",
            environment: [
                "SALU_DATA_DIR": tmp.url.path,
                "SALU_TEST_MODE": "1"
            ],
            timeout: 4
        )
        
        XCTAssertEqual(result.exitCode, 0)
        XCTAssertTrue(result.stdout.strippingANSICodes().contains("战斗历史记录"))
    }
    
    /// `--stats` 应打印统计界面标题并退出（不等待输入）。
    func testStatsFlag_printsAndExits() throws {
        print("🧪 测试：testStatsFlag_printsAndExits")
        let tmp = try TemporaryDirectory()
        defer { tmp.cleanup() }
        
        let result = try CLIRunner.runGameCLI(
            arguments: ["--stats"],
            stdin: "",
            environment: [
                "SALU_DATA_DIR": tmp.url.path,
                "SALU_TEST_MODE": "1"
            ],
            timeout: 4
        )
        
        XCTAssertEqual(result.exitCode, 0)
        XCTAssertTrue(result.stdout.strippingANSICodes().contains("战绩统计"))
    }
}


