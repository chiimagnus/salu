import XCTest
@testable import GameCore

final class BattleEngineFlowEventOrderTests: XCTestCase {
    private func makeStrikeDeck(count: Int) -> [Card] {
        (1...count).map { i in Card(id: "strike_\(i)", cardId: "strike") }
    }

    private func makeEngine(
        enemyHP: Int = 40,
        deck: [Card],
        seed: UInt64 = 1
    ) -> BattleEngine {
        let player = Entity(id: "player", name: LocalizedText("玩家", "Player"), maxHP: 80)
        let enemy = Entity(
            id: "enemy",
            name: LocalizedText("木桩", "Dummy"),
            maxHP: enemyHP,
            enemyId: "jaw_worm"
        )
        return BattleEngine(player: player, enemies: [enemy], deck: deck, seed: seed)
    }

    func testStartBattle_emitsBootstrapEventsInStableOrder() {
        let engine = makeEngine(deck: makeStrikeDeck(count: 5))
        engine.startBattle()

        XCTAssertGreaterThanOrEqual(engine.events.count, 9)
        XCTAssertEqual(engine.events[0], .battleStarted)
        XCTAssertEqual(engine.events[1], .turnStarted(turn: 1))
        XCTAssertEqual(engine.events[2], .energyReset(amount: 3))

        let drawIndices = engine.events.enumerated().compactMap { index, event -> Int? in
            if case .drew = event { return index }
            return nil
        }
        XCTAssertEqual(drawIndices, [3, 4, 5, 6, 7])

        if case .enemyIntent = engine.events[8] {
            // pass
        } else {
            XCTFail("Expected enemyIntent at index 8, got \(engine.events[8])")
        }
    }

    func testLethalPlay_emitsPlayedDeathDamageBattleWonInOrder() {
        let engine = makeEngine(enemyHP: 1, deck: [Card(id: "strike_1", cardId: "strike")])
        engine.startBattle()
        engine.clearEvents()

        XCTAssertTrue(engine.handleAction(.playCard(handIndex: 0, targetEnemyIndex: 0)))

        guard let playedIndex = firstIndex(of: .played, in: engine.events) else {
            return XCTFail("Missing played event")
        }
        guard let diedIndex = firstIndex(of: .entityDied, in: engine.events) else {
            return XCTFail("Missing entityDied event")
        }
        guard let damageIndex = firstIndex(of: .damageDealt, in: engine.events) else {
            return XCTFail("Missing damageDealt event")
        }
        guard let wonIndex = firstIndex(of: .battleWon, in: engine.events) else {
            return XCTFail("Missing battleWon event")
        }

        XCTAssertLessThan(playedIndex, diedIndex)
        XCTAssertLessThan(diedIndex, damageIndex)
        XCTAssertLessThan(damageIndex, wonIndex)
        XCTAssertEqual(engine.events.filter { event in
            if case .battleWon = event { return true }
            return false
        }.count, 1)
    }

    private func firstIndex(of kind: EventKind, in events: [BattleEvent]) -> Int? {
        events.firstIndex { kind.matches($0) }
    }
}

private enum EventKind {
    case played
    case entityDied
    case damageDealt
    case battleWon

    func matches(_ event: BattleEvent) -> Bool {
        switch (self, event) {
        case (.played, .played):
            return true
        case (.entityDied, .entityDied):
            return true
        case (.damageDealt, .damageDealt):
            return true
        case (.battleWon, .battleWon):
            return true
        default:
            return false
        }
    }
}
