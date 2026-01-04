import XCTest
@testable import GameCore

final class RunStateDeckTests: XCTestCase {
    func testAddCardToDeck_generatesStableInstanceId() {
        var runState = RunState.newRun(seed: 1)
        
        // starter deck 本来就有 inflame_1
        runState.addCardToDeck(cardId: "inflame")
        
        guard let last = runState.deck.last else {
            XCTFail("deck 为空")
            return
        }
        
        XCTAssertEqual(last.cardId.rawValue, "inflame")
        XCTAssertEqual(last.id, "inflame_2")
    }
}


