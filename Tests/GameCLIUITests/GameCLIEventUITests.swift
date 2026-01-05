import Foundation
import GameCore
import XCTest

/// GameCLI 事件房间（P5）黑盒「UI」测试
///
/// 目的：
/// - 验证事件节点可进入并展示事件内容
/// - 验证选择选项后 RunSnapshot 产生可观察的变化（金币/遗物/卡牌升级等）
final class GameCLIEventUITests: XCTestCase {
    func testEventRoom_choiceUpdatesSave() throws {
        print("🧪 测试：testEventRoom_choiceUpdatesSave")
        let tmp = try TemporaryDirectory()
        defer { tmp.cleanup() }
        
        let env: [String: String] = [
            "SALU_DATA_DIR": tmp.url.path,
            "SALU_TEST_MODE": "1",
            "SALU_TEST_MAP": "event"
        ]
        
        let seed: UInt64 = 123
        
        let result = try CLIRunner.runGameCLI(
            arguments: ["--seed", "\(seed)"],
            // 新冒险 → 起点 → 事件 → 选项 1 → Enter 继续 → 回地图 q → 退出
            stdin: "1\n1\n1\n1\n\nq\n4\n",
            environment: env,
            timeout: 12
        )
        
        XCTAssertEqual(result.exitCode, 0)
        
        let output = result.stdout.strippingANSICodes()
        XCTAssertTrue(output.contains("事件"), "期望出现事件界面相关文本（stdout）")
        
        let saveURL = tmp.url.appendingPathComponent("run_save.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: saveURL.path), "期望生成 run_save.json")
        
        let data = try Data(contentsOf: saveURL)
        let snapshot = try JSONDecoder().decode(RunSnapshot.self, from: data)
        
        // 选择 1 后至少有一项变化（不同事件可能影响不同字段）
        let baselineGold = RunState.startingGold
        let baselineRelicCount = 1 // burning_blood
        let baselineHasUpgraded = false
        
        let hasGoldChanged = snapshot.gold != baselineGold
        let hasRelicChanged = snapshot.relicIds.count != baselineRelicCount
        let hasUpgradedCard = snapshot.deck.contains { $0.cardId.contains("+") } != baselineHasUpgraded
        
        XCTAssertTrue(hasGoldChanged || hasRelicChanged || hasUpgradedCard, "期望事件选择对冒险状态产生可观察变化（gold/relic/deck）")
    }
}


