import XCTest
@testable import GameCore

final class SeerEventDefinitionsTests: XCTestCase {
    func testSeerSequenceChamberEvent_generatesExpectedOptionsAndEffects() {
        var rng = SeededRNG(seed: 1)
        let ctx = EventContext(
            seed: 1,
            floor: 1,
            currentRow: 1,
            nodeId: "1_0",
            playerMaxHP: 80,
            playerCurrentHP: 80,
            gold: RunState.startingGold,
            deck: createStarterDeck(),
            relicIds: ["burning_blood"]
        )
        
        let offer = SeerSequenceChamberEvent.generate(context: ctx, rng: &rng)
        XCTAssertEqual(offer.eventId, SeerSequenceChamberEvent.id)
        XCTAssertEqual(offer.options.count, 3)
        
        // 选项 1：命运改写 + 疯狂 +3
        let o1 = offer.options[0]
        XCTAssertTrue(o1.title.contains("阅读"))
        XCTAssertTrue(o1.effects.contains(.addCard(cardId: "fate_rewrite")))
        XCTAssertTrue(o1.effects.contains(.applyStatus(statusId: "madness", stacks: 3)))
        
        // 选项 2：疯狂 -3 + 失去 10 HP
        let o2 = offer.options[1]
        XCTAssertTrue(o2.effects.contains(.applyStatus(statusId: "madness", stacks: -3)))
        XCTAssertTrue(o2.effects.contains(.takeDamage(amount: 10)))
        
        // 选项 3：无效果
        let o3 = offer.options[2]
        XCTAssertTrue(o3.effects.isEmpty)
    }
    
    func testSeerTimeRiftEvent_pastOptionHasFollowUpWhenUpgradeableExists() {
        var rng = SeededRNG(seed: 2)
        let deck = createStarterDeck()
        let ctx = EventContext(
            seed: 2,
            floor: 1,
            currentRow: 1,
            nodeId: "1_0",
            playerMaxHP: 80,
            playerCurrentHP: 80,
            gold: RunState.startingGold,
            deck: deck,
            relicIds: ["burning_blood"]
        )
        
        let offer = SeerTimeRiftEvent.generate(context: ctx, rng: &rng)
        XCTAssertEqual(offer.eventId, SeerTimeRiftEvent.id)
        XCTAssertEqual(offer.options.count, 3)
        
        let upgradeable = RunState.upgradeableCardIndices(in: deck)
        let past = offer.options[0]
        if upgradeable.isEmpty {
            XCTAssertNil(past.followUp)
        } else {
            guard case .chooseUpgradeableCard(let indices)? = past.followUp else {
                return XCTFail("期望“窥视过去”为 chooseUpgradeableCard followUp")
            }
            XCTAssertEqual(indices, upgradeable)
            XCTAssertTrue(past.effects.contains(.applyStatus(statusId: "madness", stacks: 2)))
        }
        
        let future = offer.options[1]
        XCTAssertTrue(future.effects.contains(.addRelic(relicId: "broken_watch")))
        XCTAssertTrue(future.effects.contains(.applyStatus(statusId: "madness", stacks: 2)))
        
        let leave = offer.options[2]
        XCTAssertTrue(leave.effects.contains(.heal(amount: 10)))
    }
    
    func testSeerMadProphetEvent_hasBattleFollowUpAndExpectedEffects() {
        var rng = SeededRNG(seed: 3)
        let ctx = EventContext(
            seed: 3,
            floor: 1,
            currentRow: 1,
            nodeId: "1_0",
            playerMaxHP: 80,
            playerCurrentHP: 80,
            gold: RunState.startingGold,
            deck: createStarterDeck(),
            relicIds: ["burning_blood"]
        )
        
        let offer = SeerMadProphetEvent.generate(context: ctx, rng: &rng)
        XCTAssertEqual(offer.eventId, SeerMadProphetEvent.id)
        XCTAssertEqual(offer.options.count, 3)
        
        let o1 = offer.options[0]
        XCTAssertTrue(o1.effects.contains(.addCard(cardId: "abyssal_gaze")))
        XCTAssertTrue(o1.effects.contains(.applyStatus(statusId: "madness", stacks: 4)))
        
        let o2 = offer.options[1]
        guard case .startEliteBattle(let enemyId)? = o2.followUp else {
            return XCTFail("期望“打断他”为 startEliteBattle followUp")
        }
        XCTAssertEqual(enemyId, "mad_prophet")
        
        let o3 = offer.options[2]
        XCTAssertTrue(o3.effects.contains(.loseGold(amount: 30)))
        XCTAssertTrue(o3.effects.contains(.heal(amount: 15)))
        XCTAssertTrue(o3.effects.contains(.applyStatus(statusId: "madness", stacks: -2)))
    }
}

