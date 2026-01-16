import Foundation
import GameCore
import XCTest

/// GameCLI 存档系统的黑盒「UI」测试
///
/// 目的：
/// - 验证“节点完成后自动保存”确实发生（生成 `run_save.json`）
/// - 验证“继续上次冒险”确实能加载存档并给出提示（不是仅靠脚本 grep）
final class GameCLISaveUITests: XCTestCase {
    /// 创建存档后再次启动，主菜单应出现“继续上次冒险”，并打印“存档加载成功！”。
    func testSaveCreateAndContinue() throws {
        print("🧪 测试：testSaveCreateAndContinue")
        let tmp = try TemporaryDirectory()
        defer { tmp.cleanup() }
        
        let env = [
            "SALU_DATA_DIR": tmp.url.path,
            "SALU_TEST_MODE": "1"
        ]
        
        // 运行 1：开始新冒险 → 选择起点节点（会自动完成并触发保存）→ 返回主菜单 → 退出
        _ = try CLIRunner.runGameCLI(
            arguments: ["--seed", "123"],
            stdin: "1\n1\nq\n4\n",
            environment: env,
            timeout: 8
        )
        
        let saveURL = tmp.url.appendingPathComponent("run_save.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: saveURL.path), "期望生成 run_save.json")
        
        let data = try Data(contentsOf: saveURL)
        let snapshot = try JSONDecoder().decode(RunSnapshot.self, from: data)
        XCTAssertEqual(snapshot.seed, 123, "存档 seed 应来自本次冒险 seed")
        XCTAssertFalse(snapshot.mapNodes.isEmpty, "存档应包含地图节点数据")
        
        // 运行 2：继续上次冒险 → 返回主菜单 → 退出
        let result2 = try CLIRunner.runGameCLI(
            arguments: ["--seed", "999"], // continueRun 不依赖 seed，这里确保不会误用
            stdin: "1\nq\n4\n",
            environment: env,
            timeout: 8
        )
        
        let out2 = result2.stdout.strippingANSICodes()
        XCTAssertTrue(out2.contains("Save loaded!"), "Expected save loaded prompt (stdout)")
    }
}

