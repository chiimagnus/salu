import Foundation
import XCTest
@testable import GameCLI
import GameCore

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
    
    private func withInput(_ inputs: [String], _ work: () -> Void) {
        var queue = inputs
        let previous = InputReader.readLine
        InputReader.readLine = {
            guard !queue.isEmpty else {
                return nil
            }
            return queue.removeFirst()
        }
        defer {
            InputReader.readLine = previous
        }
        work()
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
            logBattleEvents: { _ in },
            logLine: { _ in },
            battleLoop: { _, _ in },
            createEnemy: { _, _, _ in Entity(id: "enemy#0", name: "敌人", maxHP: 1, enemyId: "jaw_worm") },
            historyService: historyService
        )
        
        withInput(["1", "d", "1", "0"]) {
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
