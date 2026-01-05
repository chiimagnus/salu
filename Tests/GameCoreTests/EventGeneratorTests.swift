import XCTest
@testable import GameCore

final class EventGeneratorTests: XCTestCase {
    func testEventGenerator_isDeterministic() {
        print("🧪 测试：testEventGenerator_isDeterministic")
        let run = RunState.newRun(seed: 123)
        let context = EventContext(
            seed: run.seed,
            floor: run.floor,
            currentRow: run.currentRow,
            nodeId: "3_0",
            playerMaxHP: run.player.maxHP,
            playerCurrentHP: run.player.currentHP,
            gold: run.gold,
            deck: run.deck,
            relicIds: run.relicManager.all
        )
        
        let a = EventGenerator.generate(context: context)
        let b = EventGenerator.generate(context: context)
        XCTAssertEqual(a, b)
        XCTAssertFalse(a.options.isEmpty)
    }
    
    func testScavengerEvent_generatesValuesInExpectedRanges() {
        print("🧪 测试：testScavengerEvent_generatesValuesInExpectedRanges")
        let run = RunState.newRun(seed: 1)
        var rng = SeededRNG(seed: 999)
        let context = EventContext(
            seed: run.seed,
            floor: run.floor,
            currentRow: 5,
            nodeId: "5_0",
            playerMaxHP: run.player.maxHP,
            playerCurrentHP: run.player.currentHP,
            gold: run.gold,
            deck: run.deck,
            relicIds: run.relicManager.all
        )
        
        let offer = ScavengerEvent.generate(context: context, rng: &rng)
        XCTAssertEqual(offer.eventId, ScavengerEvent.id)
        XCTAssertEqual(offer.options.count, 3)
        
        // 选项 1：gainGold 30~50
        let o1 = offer.options[0]
        XCTAssertEqual(o1.effects.count, 1)
        if case .gainGold(let amount) = o1.effects[0] {
            XCTAssertTrue((30...50).contains(amount))
        } else {
            XCTFail("期望第一个选项产生 gainGold")
        }
        
        // 选项 2：takeDamage 6~10 + gainGold 70~90
        let o2 = offer.options[1]
        XCTAssertEqual(o2.effects.count, 2)
        var damage: Int?
        var gold: Int?
        for e in o2.effects {
            switch e {
            case .takeDamage(let a): damage = a
            case .gainGold(let a): gold = a
            default: break
            }
        }
        XCTAssertTrue((6...10).contains(damage ?? -1))
        XCTAssertTrue((70...90).contains(gold ?? -1))
    }
    
    func testAltarEvent_sacrificeOption_excludesStarterAndOwned() {
        print("🧪 测试：testAltarEvent_sacrificeOption_excludesStarterAndOwned")
        let run = RunState.newRun(seed: 1)
        var rng = SeededRNG(seed: 1)
        let context = EventContext(
            seed: run.seed,
            floor: run.floor,
            currentRow: 5,
            nodeId: "5_0",
            playerMaxHP: run.player.maxHP,
            playerCurrentHP: run.player.currentHP,
            gold: 999,
            deck: run.deck,
            relicIds: ["burning_blood"]
        )
        
        let offer = AltarEvent.generate(context: context, rng: &rng)
        XCTAssertEqual(offer.eventId, AltarEvent.id)
        
        let relicIdsFromEffects: [RelicID] = offer.options.flatMap { option in
            option.effects.compactMap { effect in
                if case .addRelic(let relicId) = effect { return relicId }
                return nil
            }
        }
        for relicId in relicIdsFromEffects {
            XCTAssertNotEqual(relicId, RelicID("burning_blood"))
            XCTAssertNotEqual(RelicRegistry.require(relicId).rarity, .starter)
        }
    }
    
    func testTrainingEvent_upgradeOption_targetsFirstUpgradeableCardWhenAvailable() {
        print("🧪 测试：testTrainingEvent_upgradeOption_targetsFirstUpgradeableCardWhenAvailable")
        let run = RunState.newRun(seed: 1)
        var rng = SeededRNG(seed: 2)
        let context = EventContext(
            seed: run.seed,
            floor: run.floor,
            currentRow: 5,
            nodeId: "5_0",
            playerMaxHP: run.player.maxHP,
            playerCurrentHP: run.player.currentHP,
            gold: run.gold,
            deck: run.deck,
            relicIds: run.relicManager.all
        )
        
        let offer = TrainingEvent.generate(context: context, rng: &rng)
        XCTAssertEqual(offer.eventId, TrainingEvent.id)
        
        // 牌组第一张是 strike_1，且可升级，故训练的“专注训练”应升级 index 0
        if let upgrade = offer.options.first(where: { $0.effects.contains(where: { if case .upgradeCard = $0 { return true }; return false }) }) {
            guard let effect = upgrade.effects.first else { return XCTFail("升级选项应包含 effect") }
            if case .upgradeCard(let deckIndex) = effect {
                XCTAssertEqual(deckIndex, 0)
            } else {
                XCTFail("期望 upgradeCard effect")
            }
        } else {
            XCTFail("期望存在升级选项")
        }
    }
}


