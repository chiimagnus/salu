import Foundation
import XCTest
@testable import GameCLI
import GameCore

#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

final class ShopRoomHandlerTests: XCTestCase {
    private final class InMemoryRunSaveStore: RunSaveStore, @unchecked Sendable {
        private var snapshot: RunSnapshot?
        
        func load() throws -> RunSnapshot? { snapshot }
        func save(_ snapshot: RunSnapshot) throws { self.snapshot = snapshot }
        func clear() throws { snapshot = nil }
    }
    
    private final class InMemoryBattleHistoryStore: BattleHistoryStore, @unchecked Sendable {
        func load() throws -> [BattleRecord] { [] }
        func append(_ record: BattleRecord) throws {}
        func clear() throws {}
    }
    
    private func withStdin(_ input: String, _ work: () -> Void) {
        var fds: [Int32] = [0, 0]
        XCTAssertEqual(pipe(&fds), 0)
        
        let readFD = fds[0]
        let writeFD = fds[1]
        
        let savedStdin = dup(STDIN_FILENO)
        XCTAssertNotEqual(savedStdin, -1)
        
        XCTAssertEqual(dup2(readFD, STDIN_FILENO), STDIN_FILENO)
        clearerr(stdin)
        close(readFD)
        
        let data = input.data(using: .utf8) ?? Data()
        data.withUnsafeBytes { ptr in
            guard let base = ptr.baseAddress else { return }
            write(writeFD, base, data.count)
        }
        close(writeFD)
        
        work()
        
        XCTAssertEqual(dup2(savedStdin, STDIN_FILENO), STDIN_FILENO)
        clearerr(stdin)
        close(savedStdin)
    }
    
    func testShopRoomHandler_buyAndRemove_updatesRunStateAndPersists() throws {
        print("🧪 测试：testShopRoomHandler_buyAndRemove_updatesRunStateAndPersists")
        let handler = ShopRoomHandler()
        
        let node = MapNode(id: "3_0", row: 3, column: 0, roomType: .shop, connections: [], isCompleted: false, isAccessible: true)
        var runState = RunState(
            player: createDefaultPlayer(),
            deck: [
                Card(id: "strike_1", cardId: "strike"),
                Card(id: "defend_1", cardId: "defend"),
            ],
            gold: 200,
            relicManager: RelicManager(),
            map: [node],
            seed: 7,
            floor: 1
        )
        runState.currentNodeId = node.id
        
        let shopContext = ShopContext(seed: runState.seed, floor: runState.floor, currentRow: runState.currentRow, nodeId: node.id)
        let inventory = ShopInventory.generate(context: shopContext)
        let firstOffer = try XCTUnwrap(inventory.cardOffers.first)
        
        let historyService = HistoryService(store: InMemoryBattleHistoryStore())
        let context = RoomContext(
            appendEvents: { _ in },
            clearEvents: { },
            appendRunLog: { _ in },
            battleLoop: { _, _ in },
            createEnemy: { _, _ in Entity(id: "enemy", name: "敌人", maxHP: 1, enemyId: "jaw_worm") },
            historyService: historyService
        )
        
        withStdin("1\nd\n1\n0\n") {
            _ = handler.run(node: node, runState: &runState, context: context)
        }
        
        XCTAssertTrue(runState.map.first?.isCompleted == true, "商店节点应标记为完成")
        XCTAssertEqual(runState.gold, 200 - firstOffer.price - ShopPricing.removeCardPrice)
        XCTAssertTrue(runState.deck.contains { $0.cardId == firstOffer.cardId }, "购买的卡牌应加入牌组")
        XCTAssertFalse(runState.deck.contains { $0.cardId == "strike" }, "删牌应移除第一张 Strike")
        
        let store = InMemoryRunSaveStore()
        let service = SaveService(store: store)
        service.saveRun(runState)
        let loaded = try XCTUnwrap(try service.loadRun())
        
        XCTAssertEqual(loaded.gold, runState.gold)
        XCTAssertEqual(loaded.deck.map(\.cardId.rawValue), runState.deck.map(\.cardId.rawValue))
    }
}
