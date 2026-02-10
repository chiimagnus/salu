import XCTest
import GameCore

final class SeerRelicsAndMadnessTests: XCTestCase {
    func testThirdEye_triggersOnBattleStart_emitsForesightChosen() {
        let seed: UInt64 = 7
        let player = createDefaultPlayer()
        let enemy = Entity(id: "e0", name: LocalizedText("测试敌人", "测试敌人"), maxHP: 40, enemyId: "shadow_stalker")
        
        var relics = RelicManager()
        relics.add("third_eye")
        
        // deck 里保证至少有一张攻击牌，便于预知选择逻辑稳定
        let deck: [Card] = [
            .init(id: "k1", cardId: "strike"),
            .init(id: "d1", cardId: "defend"),
            .init(id: "k2", cardId: "strike"),
            .init(id: "d2", cardId: "defend"),
            .init(id: "k3", cardId: "strike"),
            .init(id: "d3", cardId: "defend"),
        ]
        
        let engine = BattleEngine(player: player, enemies: [enemy], deck: deck, relicManager: relics, seed: seed)
        engine.startBattle()

        // 第三只眼：battleStart -> foresight(2) -> 挂起等待选择
        guard case .some(.foresight(_, let fromCount)) = engine.pendingInput else {
            return XCTFail("期望 battleStart 后进入 pending foresight")
        }
        XCTAssertEqual(fromCount, 2)

        engine.clearEvents()
        _ = engine.submitForesightChoice(index: 0)

        // 选择后才会 emit foresightChosen(...)
        XCTAssertTrue(engine.events.contains(where: {
            if case .foresightChosen(_, let c) = $0 { return c == 2 }
            return false
        }))
    }

    func testAbyssalEye_triggersForesightAndMadnessOnBattleStart() {
        let seed: UInt64 = 8
        let player = createDefaultPlayer()
        let enemy = Entity(id: "e0", name: LocalizedText("测试敌人", "测试敌人"), maxHP: 40, enemyId: "shadow_stalker")

        var relics = RelicManager()
        relics.add("abyssal_eye")

        let deck: [Card] = [
            .init(id: "k1", cardId: "strike"),
            .init(id: "d1", cardId: "defend"),
            .init(id: "k2", cardId: "strike"),
            .init(id: "d2", cardId: "defend"),
            .init(id: "k3", cardId: "strike"),
            .init(id: "d3", cardId: "defend"),
            .init(id: "k4", cardId: "strike"),
        ]

        let engine = BattleEngine(player: player, enemies: [enemy], deck: deck, relicManager: relics, seed: seed)
        engine.startBattle()

        guard case .some(.foresight(_, let fromCount)) = engine.pendingInput else {
            return XCTFail("期望 battleStart 后进入 pending foresight")
        }
        XCTAssertEqual(fromCount, 3)

        XCTAssertEqual(engine.state.player.statuses.stacks(of: "madness"), 1)

        engine.clearEvents()
        _ = engine.submitForesightChoice(index: 0)

        XCTAssertTrue(engine.events.contains(where: {
            if case .foresightChosen(_, let c) = $0 { return c == 3 }
            return false
        }))
    }
    
    func testSanityAnchor_delaysThreshold2Weak() {
        let seed: UInt64 = 9
        var player = createDefaultPlayer()
        player.statuses.set("madness", stacks: 6) // 没有理智之锚时，阈值2应触发虚弱
        
        let enemy = Entity(id: "e0", name: LocalizedText("测试敌人", "测试敌人"), maxHP: 40, enemyId: "shadow_stalker")
        
        var relics = RelicManager()
        relics.add("sanity_anchor")
        
        let deck: [Card] = [
            .init(id: "k1", cardId: "strike"),
            .init(id: "d1", cardId: "defend"),
            .init(id: "k2", cardId: "strike"),
            .init(id: "d2", cardId: "defend"),
            .init(id: "k3", cardId: "strike"),
            .init(id: "d3", cardId: "defend"),
        ]
        
        let engine = BattleEngine(player: player, enemies: [enemy], deck: deck, relicManager: relics, seed: seed)
        engine.startBattle()
        
        // 有理智之锚：阈值2 +3 => 9 才触发，所以 madness=6 不应给 weak
        XCTAssertEqual(engine.state.player.statuses.stacks(of: "weak"), 0)
        XCTAssertFalse(engine.events.contains(where: { event in
            if case .madnessThreshold(let level, _) = event { return level == 2 }
            return false
        }))
    }
    
    func testMadnessMask_increasesPlayerAttackDamageWhenMadnessHigh() {
        let seed: UInt64 = 11
        var playerWithHighMadness = createDefaultPlayer()
        playerWithHighMadness.statuses.set("madness", stacks: 6)
        
        let enemy = Entity(id: "e0", name: LocalizedText("测试敌人", "测试敌人"), maxHP: 200, enemyId: "shadow_stalker")
        
        var relicsWithMask = RelicManager()
        relicsWithMask.add("madness_mask")
        let relicsWithoutMask = RelicManager()
        
        // 确保第一回合手里能打出 strike
        let deck: [Card] = [
            .init(id: "k1", cardId: "strike"),
            .init(id: "k2", cardId: "strike"),
            .init(id: "k3", cardId: "strike"),
            .init(id: "d1", cardId: "defend"),
            .init(id: "d2", cardId: "defend"),
            .init(id: "d3", cardId: "defend"),
        ]
        
        // 注意：疯狂 ≥6 会在回合开始触发阈值 2 -> 获得虚弱 1
        // 所以没有疯狂面具时，Strike 6 会先被 Weak -25% => 4（向下取整）。
        // 有疯狂面具时，再 *1.5 => 6。
        
        let engineWithoutMask = BattleEngine(
            player: playerWithHighMadness,
            enemies: [enemy],
            deck: deck,
            relicManager: relicsWithoutMask,
            seed: seed
        )
        engineWithoutMask.startBattle()
        
        guard let idxA = engineWithoutMask.state.hand.firstIndex(where: { $0.cardId == "strike" }) else {
            return XCTFail("回合开始未抽到 Strike（无面具），seed/牌组不稳定")
        }
        let hpBeforeA = engineWithoutMask.state.enemies[0].currentHP
        _ = engineWithoutMask.handleAction(PlayerAction.playCard(handIndex: idxA, targetEnemyIndex: 0))
        let dmgWithoutMask = hpBeforeA - engineWithoutMask.state.enemies[0].currentHP
        
        // 重新构造一份 player（避免复用导致状态/手牌被污染）
        var playerB = createDefaultPlayer()
        playerB.statuses.set("madness", stacks: 6)
        
        let engineWithMask = BattleEngine(
            player: playerB,
            enemies: [enemy],
            deck: deck,
            relicManager: relicsWithMask,
            seed: seed
        )
        engineWithMask.startBattle()
        
        guard let idxB = engineWithMask.state.hand.firstIndex(where: { $0.cardId == "strike" }) else {
            return XCTFail("回合开始未抽到 Strike（有面具），seed/牌组不稳定")
        }
        let hpBeforeB = engineWithMask.state.enemies[0].currentHP
        _ = engineWithMask.handleAction(PlayerAction.playCard(handIndex: idxB, targetEnemyIndex: 0))
        let dmgWithMask = hpBeforeB - engineWithMask.state.enemies[0].currentHP
        
        XCTAssertEqual(dmgWithoutMask, 4)
        XCTAssertEqual(dmgWithMask, 6)
    }

    func testProphetNotes_skipsFirstRewriteMadness() {
        let seed: UInt64 = 12
        let player = createDefaultPlayer()
        let enemy = Entity(id: "e0", name: LocalizedText("测试敌人", "测试敌人"), maxHP: 40, enemyId: "shadow_stalker")

        var relics = RelicManager()
        relics.add("prophet_notes")

        let deck: [Card] = [
            .init(id: "rewrite_1", cardId: "fate_rewrite"),
            .init(id: "strike_1", cardId: "strike"),
            .init(id: "defend_1", cardId: "defend"),
            .init(id: "defend_2", cardId: "defend"),
            .init(id: "defend_3", cardId: "defend"),
        ]

        let engine = BattleEngine(player: player, enemies: [enemy], deck: deck, relicManager: relics, seed: seed)
        engine.startBattle()

        guard let rewriteIndex = engine.state.hand.firstIndex(where: { $0.cardId == "fate_rewrite" }) else {
            return XCTFail("回合开始未抽到 命运改写")
        }

        engine.clearEvents()
        _ = engine.handleAction(PlayerAction.playCard(handIndex: rewriteIndex, targetEnemyIndex: 0))

        XCTAssertEqual(engine.state.player.statuses.stacks(of: "madness"), 0)
        XCTAssertTrue(engine.events.contains(where: {
            if case .statusApplied(_, _, let effect, let stacks) = $0 {
                return effect.zhHans.contains("预言者手札") && stacks == 0
            }
            return false
        }))
    }
}
