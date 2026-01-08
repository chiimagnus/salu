import Foundation
import GameCore
import XCTest

/// 事件二次选择（升级卡牌）链路的黑盒「UI」测试
///
/// 覆盖点：
/// - `EventRoomHandler` 的 followUp: chooseUpgradeableCard
/// - `EventScreen.chooseUpgradeableCard` 的输入处理
final class GameCLITrainingEventUpgradeUITests: XCTestCase {
    func testTrainingEvent_upgradeFlow_updatesDeckInSave() throws {
        print("🧪 测试：testTrainingEvent_upgradeFlow_updatesDeckInSave")
        let tmp = try TemporaryDirectory()
        defer { tmp.cleanup() }
        
        let seed = try findSeedForEvent(expected: "training")
        
        let env: [String: String] = [
            "SALU_DATA_DIR": tmp.url.path,
            "SALU_TEST_MODE": "1",
            "SALU_TEST_MAP": "event",
        ]
        
        let result = try CLIRunner.runGameCLI(
            arguments: ["--seed", "\(seed)"],
            // 新冒险 → 起点 → 事件（训练） → 选项 1（专注训练）→ 选择第 1 张可升级卡 → q 继续 → 回地图 q → 退出
            stdin: "1\n1\n1\n1\n1\nq\nq\n4\n",
            environment: env,
            timeout: 12
        )
        
        XCTAssertEqual(result.exitCode, 0)
        
        let saveURL = tmp.url.appendingPathComponent("run_save.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: saveURL.path), "期望生成 run_save.json")
        
        let data = try Data(contentsOf: saveURL)
        let snapshot = try JSONDecoder().decode(RunSnapshot.self, from: data)
        
        // 选择第 1 个可升级卡（按牌组顺序）应升级 strike_1 → strike+
        XCTAssertTrue(snapshot.deck.contains(where: { $0.id == "strike_1" && $0.cardId == "strike+" }))
    }
    
    private func findSeedForEvent(expected eventId: EventID) throws -> UInt64 {
        let deck = createStarterDeck()
        let relicIds: [RelicID] = ["burning_blood"]
        
        for seed in UInt64(1)..<UInt64(10_000) {
            let ctx = EventContext(
                seed: seed,
                floor: 1,
                currentRow: 1,
                nodeId: "1_0",
                playerMaxHP: 80,
                playerCurrentHP: 80,
                gold: RunState.startingGold,
                deck: deck,
                relicIds: relicIds
            )
            
            let offer = EventGenerator.generate(context: ctx)
            if offer.eventId == eventId {
                return seed
            }
        }
        
        throw NSError(domain: "GameCLITrainingEventUpgradeUITests", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "未在可接受范围内找到能生成 \(eventId.rawValue) 的 seed"
        ])
    }
}


