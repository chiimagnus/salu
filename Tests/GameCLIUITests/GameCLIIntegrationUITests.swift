import XCTest

/// GameCLI 综合集成测试 - 整合多个小型烟雾测试
///
/// 目的：
/// - 验证 CLI 各主要流程端到端可达（启动、战斗、帮助、设置等）
/// - 合并原有的多个小型单一功能 UI 测试，减少文件数量
/// - 保持测试覆盖的同时提升维护效率
final class GameCLIIntegrationUITests: XCTestCase {
    
    // MARK: - 启动与主菜单测试
    
    /// 无存档时：主菜单应包含"开始冒险"，并且输入 `3` 可以正常退出。
    /// 原文件: GameCLIStartupUITests.swift
    func testMainMenuBootAndExit_withoutSave() throws {
        print("🧪 测试：testMainMenuBootAndExit_withoutSave")
        let tmp = try TemporaryDirectory()
        defer { tmp.cleanup() }
        
        let result = try CLIRunner.runGameCLI(
            arguments: ["--seed", "1"],
            stdin: "3\n",
            environment: [
                "SALU_DATA_DIR": tmp.url.path,
                "SALU_TEST_MODE": "1"
            ],
            timeout: 6
        )
        
        XCTAssertEqual(result.exitCode, 0)
        
        let output = result.stdout.strippingANSICodes()
        XCTAssertTrue(output.contains("杀戮尖塔"), "期望出现游戏标题/主菜单（stdout）")
        XCTAssertTrue(output.contains("开始冒险"), "期望出现无存档时的菜单项（stdout）")
    }
    
    // MARK: - 战斗界面测试
    
    /// 进入第一场战斗后退出，stdout 应出现敌人标识（👹）或意图字段。
    /// 原文件: GameCLIBattleUITests.swift
    func testEnterBattleScreenAndQuit_doesNotHang() throws {
        print("🧪 测试：testEnterBattleScreenAndQuit_doesNotHang")
        let tmp = try TemporaryDirectory()
        defer { tmp.cleanup() }
        
        let result = try CLIRunner.runGameCLI(
            arguments: ["--seed", "1"],
            // 新冒险 → 起点 → 第一战斗节点 → 战斗界面 q 退出 → 冒险结果 q 返回 → 主菜单退出
            stdin: "1\n1\n1\nq\nq\n3\n",
            environment: [
                "SALU_DATA_DIR": tmp.url.path,
                "SALU_TEST_MODE": "1"
            ],
            timeout: 10
        )
        
        XCTAssertEqual(result.exitCode, 0)
        
        let output = result.stdout.strippingANSICodes()
        XCTAssertTrue(output.contains("👹") || output.contains("意图"), "期望出现战斗界面关键标识（stdout）")
    }
    
    // MARK: - 帮助界面测试
    
    /// 进入战斗后按 `h` 打开帮助，再返回并退出，stdout 应包含"游戏帮助"。
    /// 原文件: GameCLIHelpUITests.swift
    func testBattleHelp_canOpenAndReturn() throws {
        print("🧪 测试：testBattleHelp_canOpenAndReturn")
        let tmp = try TemporaryDirectory()
        defer { tmp.cleanup() }
        
        let result = try CLIRunner.runGameCLI(
            arguments: ["--seed", "1"],
            // 新冒险 → 起点 → 第一战斗 → h 帮助 → q 返回游戏 → q 退出战斗 → 冒险结果 q 返回 → 主菜单退出
            stdin: "1\n1\n1\nh\nq\nq\nq\n3\n",
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
    
    // MARK: - 设置菜单测试
    
    /// 从主菜单进入设置，查看统计并清除历史（yes 分支），最终返回主菜单并退出。
    /// 原文件: GameCLISettingsUITests.swift
    func testSettingsMenu_statsAndClearHistory_canNavigate() throws {
        print("🧪 测试：testSettingsMenu_statsAndClearHistory_canNavigate")
        let tmp = try TemporaryDirectory()
        defer { tmp.cleanup() }
        
        // 输入序列：
        // 2 - 进入设置菜单
        // 2 - 查看统计
        // q - 返回设置菜单
        // 3 - 清除历史
        // yes - 确认清除
        // q - 返回设置菜单
        // 0 - 返回主菜单
        // 3 - 退出游戏
        let result = try CLIRunner.runGameCLI(
            arguments: ["--seed", "1"],
            stdin: "2\n2\nq\n3\nyes\nq\n0\n3\n",
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
    
    // MARK: - 真实模式烟雾测试
    
    /// 不开启 `SALU_TEST_MODE` 的 CLI smoke 测试
    /// 新冒险 → 起点 → 进入战斗 → 直接 `q` 退出战斗（视为失败结束 run）→ 返回主菜单 → 退出。
    /// 原文件: GameCLISmokeNoTestModeUITests.swift
    func testSmoke_realMode_enterBattleAndQuit_doesNotHang() throws {
        print("🧪 测试：testSmoke_realMode_enterBattleAndQuit_doesNotHang")
        let tmp = try TemporaryDirectory()
        defer { tmp.cleanup() }
        
        let result = try CLIRunner.runGameCLI(
            arguments: ["--seed", "1"],
            stdin: "1\n1\n1\nq\nq\n3\n",
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
