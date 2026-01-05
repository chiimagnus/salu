import Foundation
import XCTest
@testable import GameCLI
import GameCore

#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

/// GameCLI 屏幕渲染 + RoomHandler 覆盖测试（白盒）
///
/// 目的：
/// - 覆盖 GameCLI 中“非空数据分支”的渲染逻辑（History/Statistics/Result）
/// - 覆盖 BossRoomHandler 的可达性与胜利路径（不依赖长链路 UI 跑完整 15 层）
/// - 让覆盖率提升来自**真实的可执行路径**，而不是“为了 100% 的空调用”
final class ScreenAndRoomCoverageTests: XCTestCase {
    // MARK: - Helpers
    
    private final class InMemoryBattleHistoryStore: BattleHistoryStore, @unchecked Sendable {
        private(set) var records: [BattleRecord] = []
        
        func load() throws -> [BattleRecord] { records }
        func append(_ record: BattleRecord) throws { records.append(record) }
        func clear() throws { records.removeAll() }
    }
    
    private func makeRecord(seed: UInt64, won: Bool, turns: Int) -> BattleRecord {
        BattleRecord(
            seed: seed,
            won: won,
            turnsPlayed: turns,
            playerName: "玩家",
            playerMaxHP: 80,
            playerFinalHP: won ? 50 : 0,
            enemyName: "敌人",
            enemyMaxHP: 40,
            enemyFinalHP: won ? 0 : 10,
            cardsPlayed: 3,
            strikesPlayed: 2,
            defendsPlayed: 1,
            totalDamageDealt: 10,
            totalDamageTaken: 5,
            totalBlockGained: 8
        )
    }
    
    private func captureStdout(_ work: () -> Void) -> String {
        var fds: [Int32] = [0, 0]
        XCTAssertEqual(pipe(&fds), 0)
        
        let readFD = fds[0]
        let writeFD = fds[1]
        
        let savedStdout = dup(STDOUT_FILENO)
        XCTAssertNotEqual(savedStdout, -1)
        
        XCTAssertEqual(dup2(writeFD, STDOUT_FILENO), STDOUT_FILENO)
        close(writeFD)
        
        work()
        fflush(stdout)
        
        XCTAssertEqual(dup2(savedStdout, STDOUT_FILENO), STDOUT_FILENO)
        close(savedStdout)
        
        let handle = FileHandle(fileDescriptor: readFD, closeOnDealloc: true)
        let data = handle.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    // MARK: - Tests
    
    func testHistoryScreen_withRecords_rendersTableAndCountLine() {
    
        print("🧪 测试：testHistoryScreen_withRecords_rendersTableAndCountLine")
        let store = InMemoryBattleHistoryStore()
        let service = HistoryService(store: store)
        service.addRecord(makeRecord(seed: 1, won: true, turns: 3))
        service.addRecord(makeRecord(seed: 2, won: false, turns: 6))
        
        let output = captureStdout {
            HistoryScreen.show(historyService: service)
        }.strippingANSICodes()
        
        XCTAssertTrue(output.contains("战斗历史记录"))
        XCTAssertTrue(output.contains("序号"))
        XCTAssertTrue(output.contains("显示最近"), "期望出现“显示最近 N 场战斗”的统计行")
    }
    
    func testStatisticsScreen_withRecords_rendersSummary() {
    
        print("🧪 测试：testStatisticsScreen_withRecords_rendersSummary")
        let store = InMemoryBattleHistoryStore()
        let service = HistoryService(store: store)
        service.addRecord(makeRecord(seed: 1, won: true, turns: 3))
        service.addRecord(makeRecord(seed: 2, won: false, turns: 6))
        
        let output = captureStdout {
            StatisticsScreen.show(historyService: service)
        }.strippingANSICodes()
        
        XCTAssertTrue(output.contains("战绩统计"))
        XCTAssertTrue(output.contains("总场次"))
        XCTAssertTrue(output.contains("胜率"))
    }
    
    func testResultScreen_showFinal_withRecord_rendersVictoryAndStatsPanel() {
    
        print("🧪 测试：testResultScreen_showFinal_withRecord_rendersVictoryAndStatsPanel")
        var player = Entity(id: "player", name: "玩家", maxHP: 80)
        player.currentHP = 55
        
        let enemy = Entity(id: "enemy", name: "敌人", maxHP: 40, enemyId: "jaw_worm")
        var state = BattleState(player: player, enemy: enemy)
        state.turn = 3
        state.playerWon = true
        
        let record = makeRecord(seed: 1, won: true, turns: 3)
        
        let output = captureStdout {
            ResultScreen.showFinal(state: state, record: record)
        }.strippingANSICodes()
        
        XCTAssertTrue(output.contains("战 斗 胜 利") || output.contains("战斗胜利"))
        XCTAssertTrue(output.contains("本局统计"))
        XCTAssertTrue(output.contains("使用 --history"), "期望出现后续提示文案（stdout）")
    }
    
    func testBossRoomHandler_win_returnsRunEndedTrue_andWritesHistory() {
    
        print("🧪 测试：testBossRoomHandler_win_returnsRunEndedTrue_andWritesHistory")
        let store = InMemoryBattleHistoryStore()
        let historyService = HistoryService(store: store)
        
        var run = RunState(
            player: createDefaultPlayer(),
            deck: [Card(id: "strike_1", cardId: "strike")],
            relicManager: RelicManager(),
            map: [],
            seed: 1,
            floor: 1
        )
        
        let handler = BossRoomHandler()
        let bossNode = MapNode(id: "14_0", row: 14, column: 0, roomType: .boss)
        
        let context = RoomContext(
            appendEvents: { _ in },
            clearEvents: { },
            battleLoop: { engine, _ in
                // 让战斗在测试里“稳定且快速”结束：打一张 Strike（敌人 HP=1）
                _ = engine.handleAction(.playCard(handIndex: 0))
            },
            createEnemy: { enemyId, _ in
                Entity(id: enemyId.rawValue, name: "Boss", maxHP: 1, enemyId: enemyId)
            },
            historyService: historyService
        )
        
        let result = handler.run(node: bossNode, runState: &run, context: context)
        switch result {
        case .runEnded(let won):
            XCTAssertTrue(won)
        default:
            XCTFail("BossRoomHandler 期望返回 runEnded(won: true)")
        }
        
        XCTAssertEqual(store.records.count, 1, "期望写入 1 条战斗记录")
        XCTAssertEqual(store.records.first?.won, true)
    }
}

private extension String {
    func strippingANSICodes() -> String {
        replacingOccurrences(
            of: "\u{001B}\\[[0-9;?]*[ -/]*[@-~]",
            with: "",
            options: .regularExpression
        )
    }
}


