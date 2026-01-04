import XCTest
@testable import GameCLI
import GameCore

/// SaveService 白盒单元测试
///
/// 目的：
/// - 覆盖 GameCLI 的存档“业务逻辑层”（snapshot ↔︎ restore），避免只靠黑盒 UI 测试验证
/// - 明确验证错误路径：版本不兼容 / 存档数据损坏（未知卡牌/遗物）
final class SaveServiceTests: XCTestCase {
    private final class InMemoryRunSaveStore: RunSaveStore, @unchecked Sendable {
        private var snapshot: RunSnapshot?
        
        func load() throws -> RunSnapshot? { snapshot }
        func save(_ snapshot: RunSnapshot) throws { self.snapshot = snapshot }
        func clear() throws { snapshot = nil }
    }
    
    func testSaveAndLoad_roundTripPreservesKeyFields() throws {
        let store = InMemoryRunSaveStore()
        let service = SaveService(store: store)
        
        var run = RunState.newRun(seed: 42)
        run.player.currentHP = 55
        run.player.statuses.set("strength", stacks: 2)
        run.addCardToDeck(cardId: "inflame")
        run.relicManager.add("lantern")
        
        service.saveRun(run)
        let loaded = try XCTUnwrap(try service.loadRun())
        
        XCTAssertEqual(loaded.seed, 42)
        XCTAssertEqual(loaded.player.currentHP, 55)
        XCTAssertEqual(loaded.player.statuses.stacks(of: "strength"), 2)
        XCTAssertEqual(loaded.deck.map(\.cardId.rawValue), run.deck.map(\.cardId.rawValue))
        XCTAssertTrue(loaded.relicManager.all.contains("burning_blood"))
        XCTAssertTrue(loaded.relicManager.all.contains("lantern"))
        XCTAssertEqual(loaded.map.count, run.map.count)
    }
    
    func testRestoreRunState_incompatibleVersion_throws() {
        let service = SaveService(store: InMemoryRunSaveStore())
        let run = RunState.newRun(seed: 1)
        let snapshot = service.createSnapshot(from: run)
        
        let incompatible = RunSnapshot(
            version: 0,
            seed: snapshot.seed,
            floor: snapshot.floor,
            mapNodes: snapshot.mapNodes,
            currentNodeId: snapshot.currentNodeId,
            player: snapshot.player,
            deck: snapshot.deck,
            relicIds: snapshot.relicIds,
            isOver: snapshot.isOver,
            won: snapshot.won
        )
        
        XCTAssertThrowsError(try service.restoreRunState(from: incompatible)) { error in
            guard case SaveError.incompatibleVersion(let saved, let current) = error else {
                return XCTFail("期望抛出 SaveError.incompatibleVersion，但得到：\(error)")
            }
            XCTAssertEqual(saved, 0)
            XCTAssertEqual(current, RunSaveVersion.current)
        }
    }
    
    func testRestoreRunState_unknownCard_throwsCorruptedSave() {
        let service = SaveService(store: InMemoryRunSaveStore())
        let run = RunState.newRun(seed: 1)
        let snapshot = service.createSnapshot(from: run)
        
        let corrupted = RunSnapshot(
            version: snapshot.version,
            seed: snapshot.seed,
            floor: snapshot.floor,
            mapNodes: snapshot.mapNodes,
            currentNodeId: snapshot.currentNodeId,
            player: snapshot.player,
            deck: [RunSnapshot.CardData(id: "bad_1", cardId: "unknown_card")],
            relicIds: snapshot.relicIds,
            isOver: snapshot.isOver,
            won: snapshot.won
        )
        
        XCTAssertThrowsError(try service.restoreRunState(from: corrupted)) { error in
            guard case SaveError.corruptedSave(let reason) = error else {
                return XCTFail("期望抛出 SaveError.corruptedSave，但得到：\(error)")
            }
            XCTAssertTrue(reason.contains("未知卡牌"), "reason 应包含“未知卡牌”，实际：\(reason)")
        }
    }
    
    func testRestoreRunState_unknownRelic_throwsCorruptedSave() {
        let service = SaveService(store: InMemoryRunSaveStore())
        let run = RunState.newRun(seed: 1)
        let snapshot = service.createSnapshot(from: run)
        
        let corrupted = RunSnapshot(
            version: snapshot.version,
            seed: snapshot.seed,
            floor: snapshot.floor,
            mapNodes: snapshot.mapNodes,
            currentNodeId: snapshot.currentNodeId,
            player: snapshot.player,
            deck: snapshot.deck,
            relicIds: ["unknown_relic"],
            isOver: snapshot.isOver,
            won: snapshot.won
        )
        
        XCTAssertThrowsError(try service.restoreRunState(from: corrupted)) { error in
            guard case SaveError.corruptedSave(let reason) = error else {
                return XCTFail("期望抛出 SaveError.corruptedSave，但得到：\(error)")
            }
            XCTAssertTrue(reason.contains("未知遗物"), "reason 应包含“未知遗物”，实际：\(reason)")
        }
    }
}


