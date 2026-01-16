import Foundation
import GameCore
import XCTest

/// 占卜家序列事件（P5）黑盒「UI」测试
final class GameCLISeerEventUITests: XCTestCase {
    func testSeerTimeRift_futureOption_addsBrokenWatchAndMadnessInSave() throws {
        print("🧪 测试：testSeerTimeRift_futureOption_addsBrokenWatchAndMadnessInSave")
        let tmp = try TemporaryDirectory()
        defer { tmp.cleanup() }
        
        let seed = try findSeedForEvent(expected: "seer_time_rift")
        
        let env: [String: String] = [
            "SALU_DATA_DIR": tmp.url.path,
            "SALU_TEST_MODE": "1",
            "SALU_TEST_MAP": "event",
        ]
        
        let result = try CLIRunner.runGameCLI(
            arguments: ["--seed", "\(seed)"],
            // 新冒险 → 起点 → 事件（时间裂隙）→ 选项 2（窥视未来）→ q 继续 → 回地图 q → 退出
            stdin: "1\n1\n1\n2\nq\nq\n4\n",
            environment: env,
            timeout: 12
        )
        
        XCTAssertEqual(result.exitCode, 0)
        
        let saveURL = tmp.url.appendingPathComponent("run_save.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: saveURL.path), "期望生成 run_save.json")
        
        let data = try Data(contentsOf: saveURL)
        let snapshot = try JSONDecoder().decode(RunSnapshot.self, from: data)
        
        XCTAssertTrue(snapshot.relicIds.contains("broken_watch"))
        XCTAssertEqual(snapshot.player.statuses["madness"], 2)
    }

    func testSeerTimeRift_pastOption_upgradesOneCardInSave() throws {
        print("🧪 测试：testSeerTimeRift_pastOption_upgradesOneCardInSave")
        let tmp = try TemporaryDirectory()
        defer { tmp.cleanup() }

        let seed = try findSeedForEvent(expected: "seer_time_rift")

        let env: [String: String] = [
            "SALU_DATA_DIR": tmp.url.path,
            "SALU_TEST_MODE": "1",
            "SALU_TEST_MAP": "event",
        ]

        let result = try CLIRunner.runGameCLI(
            arguments: ["--seed", "\(seed)"],
            // 新冒险 → 起点 → 事件（时间裂隙）→ 选项 1（窥视过去）→ 选择第 1 张可升级卡 → q 继续 → 回地图 q → 退出
            stdin: "1\n1\n1\n1\n1\nq\nq\n4\n",
            environment: env,
            timeout: 12
        )

        XCTAssertEqual(result.exitCode, 0)

        let saveURL = tmp.url.appendingPathComponent("run_save.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: saveURL.path), "期望生成 run_save.json")

        let data = try Data(contentsOf: saveURL)
        let snapshot = try JSONDecoder().decode(RunSnapshot.self, from: data)

        XCTAssertTrue(snapshot.deck.contains(where: { $0.cardId.contains("+") }), "期望至少有一张牌被升级为 + 版本")
    }
    
    func testSeerMadProphet_listenOption_addsAbyssalGazeAndMadnessInSave() throws {
        print("🧪 测试：testSeerMadProphet_listenOption_addsAbyssalGazeAndMadnessInSave")
        let tmp = try TemporaryDirectory()
        defer { tmp.cleanup() }
        
        let seed = try findSeedForEvent(expected: "seer_mad_prophet")
        
        let env: [String: String] = [
            "SALU_DATA_DIR": tmp.url.path,
            "SALU_TEST_MODE": "1",
            "SALU_TEST_MAP": "event",
        ]
        
        let result = try CLIRunner.runGameCLI(
            arguments: ["--seed", "\(seed)"],
            // 新冒险 → 起点 → 事件（疯狂预言者）→ 选项 1（聆听预言）→ q 继续 → 回地图 q → 退出
            stdin: "1\n1\n1\n1\nq\nq\n4\n",
            environment: env,
            timeout: 12
        )
        
        XCTAssertEqual(result.exitCode, 0)
        
        let saveURL = tmp.url.appendingPathComponent("run_save.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: saveURL.path), "期望生成 run_save.json")
        
        let data = try Data(contentsOf: saveURL)
        let snapshot = try JSONDecoder().decode(RunSnapshot.self, from: data)
        
        XCTAssertTrue(snapshot.deck.contains(where: { $0.cardId == "abyssal_gaze" }))
        XCTAssertEqual(snapshot.player.statuses["madness"], 4)
    }
    
    func testSeerMadProphet_interruptOption_entersEliteBattleAndCanAbort() throws {
        print("🧪 测试：testSeerMadProphet_interruptOption_entersEliteBattleAndCanAbort")
        let tmp = try TemporaryDirectory()
        defer { tmp.cleanup() }
        
        let seed = try findSeedForEvent(expected: "seer_mad_prophet")
        
        let env: [String: String] = [
            "SALU_DATA_DIR": tmp.url.path,
            "SALU_TEST_MODE": "1",
            "SALU_TEST_MAP": "event",
        ]
        
        let result = try CLIRunner.runGameCLI(
            arguments: ["--seed", "\(seed)"],
            // 新冒险 → 起点 → 事件（疯狂预言者）→ 选项 2（打断他）→ 进入战斗按 q 中止 → 主菜单退出
            stdin: "1\n1\n1\n2\nq\n4\n",
            environment: env,
            timeout: 12
        )
        
        XCTAssertEqual(result.exitCode, 0)
        
        let output = result.stdout.strippingANSICodes()
        XCTAssertTrue(output.contains("Mad Prophet") || output.contains("Event"), "Expected event-related output")
    }
    
    /// 事件池按 seed+node 派生，测试侧用穷举找一个能命中指定事件的 seed。
    private func findSeedForEvent(expected eventId: EventID) throws -> UInt64 {
        let deck = createStarterDeck()
        let relicIds: [RelicID] = ["burning_blood"]
        
        for seed in UInt64(1)..<UInt64(20_000) {
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
        
        throw NSError(domain: "GameCLISeerEventUITests", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "未在可接受范围内找到能生成 \(eventId.rawValue) 的 seed"
        ])
    }
}
