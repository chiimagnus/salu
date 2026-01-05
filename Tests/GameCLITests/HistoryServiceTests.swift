import XCTest
@testable import GameCLI
import GameCore

/// HistoryService 白盒单元测试
///
/// 目的：
/// - 覆盖 GameCLI 的战绩“业务逻辑层”（缓存/追加/清空），避免只靠黑盒 UI 验证
/// - 防止出现“缓存未失效导致 UI 显示旧数据”等回归
final class HistoryServiceTests: XCTestCase {
    private final class InMemoryBattleHistoryStore: BattleHistoryStore, @unchecked Sendable {
        private(set) var records: [BattleRecord] = []
        
        private(set) var loadCalls = 0
        private(set) var appendCalls = 0
        private(set) var clearCalls = 0
        
        func load() throws -> [BattleRecord] {
            loadCalls += 1
            return records
        }
        
        func append(_ record: BattleRecord) throws {
            appendCalls += 1
            records.append(record)
        }
        
        func clear() throws {
            clearCalls += 1
            records.removeAll()
        }
    }
    
    private func makeRecord(seed: UInt64, won: Bool, turns: Int) -> BattleRecord {
        BattleRecord(
            seed: seed,
            won: won,
            turnsPlayed: turns,
            playerName: "玩家",
            playerMaxHP: 80,
            playerFinalHP: 50,
            enemyName: "敌人",
            enemyMaxHP: 40,
            enemyFinalHP: 0,
            cardsPlayed: 3,
            strikesPlayed: 2,
            defendsPlayed: 1,
            totalDamageDealt: 10,
            totalDamageTaken: 5,
            totalBlockGained: 8
        )
    }
    
    func testGetAllRecords_usesCache_betweenCalls() {
    
        print("🧪 测试：testGetAllRecords_usesCache_betweenCalls")
        let store = InMemoryBattleHistoryStore()
        let service = HistoryService(store: store)
        
        _ = service.getAllRecords()
        _ = service.getAllRecords()
        
        XCTAssertEqual(store.loadCalls, 1, "期望第二次读取命中缓存，避免重复 I/O")
    }
    
    func testAddRecord_invalidatesCache_andPersistsToStore() {
    
        print("🧪 测试：testAddRecord_invalidatesCache_andPersistsToStore")
        let store = InMemoryBattleHistoryStore()
        let service = HistoryService(store: store)
        
        // 先读一次，建立缓存
        _ = service.getAllRecords()
        XCTAssertEqual(store.loadCalls, 1)
        
        // 追加记录：应写入 store，并使缓存失效
        service.addRecord(makeRecord(seed: 1, won: true, turns: 3))
        XCTAssertEqual(store.appendCalls, 1)
        
        // 再读：应触发第二次 load（因为缓存已被清掉）
        let records = service.getAllRecords()
        XCTAssertEqual(store.loadCalls, 2)
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.seed, 1)
    }
    
    func testClearHistory_clearsStore_andResetsCacheToEmpty() {
    
        print("🧪 测试：testClearHistory_clearsStore_andResetsCacheToEmpty")
        let store = InMemoryBattleHistoryStore()
        let service = HistoryService(store: store)
        
        service.addRecord(makeRecord(seed: 1, won: true, turns: 3))
        XCTAssertEqual(service.recordCount, 1)
        
        service.clearHistory()
        XCTAssertEqual(store.clearCalls, 1)
        XCTAssertEqual(service.recordCount, 0)
        XCTAssertEqual(service.getAllRecords().count, 0)
    }
}


