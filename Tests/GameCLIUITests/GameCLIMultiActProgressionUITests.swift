import Foundation
import GameCore
import XCTest

/// Act1→Act2 推进链路的黑盒「UI」测试
///
/// 目的：
/// - 覆盖“击败 Act1 Boss → 进入 Act2 地图 → 存档持久化 floor=2”的核心链路
/// - 保持稳定：依赖 SALU_TEST_MODE（敌人 HP=1、极小牌组）
final class GameCLIMultiActProgressionUITests: XCTestCase {
    func testActProgression_afterAct1Boss_advancesToAct2_andPersistsToSave() throws {
        print("🧪 测试：testActProgression_afterAct1Boss_advancesToAct2_andPersistsToSave")
        let tmp = try TemporaryDirectory()
        defer { tmp.cleanup() }
        
        let env: [String: String] = [
            "SALU_DATA_DIR": tmp.url.path,
            "SALU_TEST_MODE": "1",
            "SALU_TEST_MAP": "mini",
            "SALU_TEST_MAX_FLOOR": "2",
        ]
        
        let result = try CLIRunner.runGameCLI(
            arguments: ["--seed", "123"],
            // 新冒险 → 起点 → 精英（出牌 1 胜利）→ 跳过遗物 0 → 跳过卡牌 0
            // → Boss（出牌 1 胜利）→ 跳过遗物 0 → 进入 Act2 地图后 q 返回主菜单 → 退出 4
            stdin: "1\n1\n1\n1\n0\n0\n1\n1\n0\nq\n4\n",
            environment: env,
            timeout: 12
        )
        
        XCTAssertEqual(result.exitCode, 0)
        let output = result.stdout.strippingANSICodes()
        XCTAssertTrue(output.contains("Floor 2 Map"), "Expected Act2 map (floor=2)")
        
        let saveURL = tmp.url.appendingPathComponent("run_save.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: saveURL.path), "期望生成 run_save.json")
        
        let data = try Data(contentsOf: saveURL)
        let snapshot = try JSONDecoder().decode(RunSnapshot.self, from: data)
        XCTAssertEqual(snapshot.version, RunSaveVersion.current)
        XCTAssertEqual(snapshot.floor, 2)
        XCTAssertEqual(snapshot.maxFloor, 2)
        XCTAssertFalse(snapshot.isOver)
        XCTAssertFalse(snapshot.won)
    }
}

