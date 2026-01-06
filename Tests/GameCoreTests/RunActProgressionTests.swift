import XCTest
@testable import GameCore

/// 多幕（Act）推进测试
final class RunActProgressionTests: XCTestCase {
    func testCompleteBossNode_whenNotLastFloor_advancesToNextFloor_andResetsMap() {
        print("🧪 测试：testCompleteBossNode_whenNotLastFloor_advancesToNextFloor_andResetsMap")
        
        // floor=1, maxFloor=2：击败 Boss 后应进入 floor=2，而不是结束 run
        var run = RunState(
            player: createDefaultPlayer(),
            deck: createStarterDeck(),
            relicManager: RelicManager(),
            map: [
                MapNode(
                    id: "14_0",
                    row: 14,
                    column: 0,
                    roomType: .boss,
                    connections: [],
                    isCompleted: false,
                    isAccessible: true
                )
            ],
            seed: 42,
            floor: 1,
            maxFloor: 2
        )
        run.currentNodeId = "14_0"
        
        run.completeCurrentNode()
        
        XCTAssertEqual(run.floor, 2)
        XCTAssertFalse(run.isOver)
        XCTAssertFalse(run.won)
        XCTAssertNil(run.currentNodeId)
        XCTAssertTrue(run.map.contains(where: { $0.id == "0_0" && $0.isAccessible }), "进入下一幕后应从起点开始")
    }
    
    func testCompleteBossNode_whenLastFloor_endsRunAsWon() {
        print("🧪 测试：testCompleteBossNode_whenLastFloor_endsRunAsWon")
        
        var run = RunState(
            player: createDefaultPlayer(),
            deck: createStarterDeck(),
            relicManager: RelicManager(),
            map: [
                MapNode(
                    id: "14_0",
                    row: 14,
                    column: 0,
                    roomType: .boss,
                    connections: [],
                    isCompleted: false,
                    isAccessible: true
                )
            ],
            seed: 1,
            floor: 2,
            maxFloor: 2
        )
        run.currentNodeId = "14_0"
        
        run.completeCurrentNode()
        
        XCTAssertTrue(run.isOver)
        XCTAssertTrue(run.won)
    }
}


