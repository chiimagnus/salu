import XCTest
import GameCore

final class RunStateUpgradeTests: XCTestCase {
    func test_upgradeableCardIndices_onlyIncludesCardsWithUpgradedId() {
        let deck: [Card] = [
            Card(id: "c1", cardId: "strike"),
            Card(id: "c2", cardId: "inflame"),
        ]
        
        XCTAssertEqual(RunState.upgradeableCardIndices(in: deck), [0])
    }
    
    func test_upgradedDeck_replacesCardId_butKeepsInstanceId() {
        let deck: [Card] = [
            Card(id: "strike_1", cardId: "strike")
        ]
        
        let upgraded = RunState.upgradedDeck(from: deck, at: 0)
        XCTAssertEqual(upgraded?.count, 1)
        XCTAssertEqual(upgraded?.first?.id, "strike_1")
        XCTAssertEqual(upgraded?.first?.cardId, CardID("strike+"))
    }
    
    func test_upgradedDeck_returnsNil_forNonUpgradeableCard() {
        let deck: [Card] = [
            Card(id: "inflame_1", cardId: "inflame")
        ]
        
        XCTAssertNil(RunState.upgradedDeck(from: deck, at: 0))
    }
    
    func test_upgradeCard_mutatesDeck_andReturnsTrue() {
        var run = RunState(
            player: createDefaultPlayer(),
            deck: [Card(id: "strike_1", cardId: "strike")],
            map: MapGenerator.generateBranching(seed: 1),
            seed: 1
        )
        
        XCTAssertTrue(run.upgradeCard(at: 0))
        XCTAssertEqual(run.deck.first?.cardId, CardID("strike+"))
        XCTAssertEqual(run.deck.first?.id, "strike_1")
    }
}


