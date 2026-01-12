import XCTest
import GameCore

final class SeerMechanicsTests: XCTestCase {
    func testRewind_returnsMostRecentDiscardToHand() {
        let seed: UInt64 = 4
        let player = createDefaultPlayer()
        let enemy = Entity(id: "e0", name: "测试敌人", maxHP: 40, enemyId: "shadow_stalker")

        let deck: [Card] = [
            .init(id: "strike_1", cardId: "strike"),
            .init(id: "time_shard_1", cardId: "time_shard"),
            .init(id: "defend_1", cardId: "defend"),
            .init(id: "defend_2", cardId: "defend"),
            .init(id: "defend_3", cardId: "defend"),
        ]

        let engine = BattleEngine(
            player: player,
            enemies: [enemy],
            deck: deck,
            relicManager: RelicManager(),
            seed: seed
        )

        engine.startBattle()

        guard let strikeIndex = engine.state.hand.firstIndex(where: { $0.cardId == "strike" }) else {
            return XCTFail("回合开始未抽到 Strike")
        }
        _ = engine.handleAction(.playCard(handIndex: strikeIndex, targetEnemyIndex: 0))

        XCTAssertTrue(engine.state.discardPile.contains(where: { $0.cardId == "strike" }))

        guard let timeShardIndex = engine.state.hand.firstIndex(where: { $0.cardId == "time_shard" }) else {
            return XCTFail("回合开始未抽到 时间碎片")
        }

        engine.clearEvents()
        _ = engine.handleAction(.playCard(handIndex: timeShardIndex, targetEnemyIndex: nil))

        XCTAssertTrue(engine.state.hand.contains(where: { $0.cardId == "strike" }))
        XCTAssertTrue(engine.events.contains(where: {
            if case .rewindCard(let cardId) = $0 { return cardId == "strike" }
            return false
        }))
    }

    func testClearMadness_reducesStacksWhenPlayingMeditation() {
        let seed: UInt64 = 5
        var player = createDefaultPlayer()
        player.statuses.set("madness", stacks: 2)
        let enemy = Entity(id: "e0", name: "测试敌人", maxHP: 40, enemyId: "shadow_stalker")

        let deck: [Card] = [
            .init(id: "meditation_1", cardId: "meditation"),
            .init(id: "defend_1", cardId: "defend"),
            .init(id: "defend_2", cardId: "defend"),
            .init(id: "defend_3", cardId: "defend"),
            .init(id: "strike_1", cardId: "strike"),
        ]

        let engine = BattleEngine(
            player: player,
            enemies: [enemy],
            deck: deck,
            relicManager: RelicManager(),
            seed: seed
        )

        engine.startBattle()

        guard let meditationIndex = engine.state.hand.firstIndex(where: { $0.cardId == "meditation" }) else {
            return XCTFail("回合开始未抽到 冥想")
        }

        engine.clearEvents()
        _ = engine.handleAction(.playCard(handIndex: meditationIndex, targetEnemyIndex: nil))

        XCTAssertEqual(engine.state.player.statuses.stacks(of: "madness"), 0)
        XCTAssertTrue(engine.events.contains(where: {
            if case .madnessCleared(let amount) = $0 { return amount == 2 }
            return false
        }))
    }

    func testRewriteIntent_updatesPlannedMove_andAddsMadness() {
        let seed: UInt64 = 6
        let player = createDefaultPlayer()
        let enemy = Entity(id: "e0", name: "测试敌人", maxHP: 40, enemyId: "shadow_stalker")

        let deck: [Card] = [
            .init(id: "fate_rewrite_1", cardId: "fate_rewrite"),
            .init(id: "defend_1", cardId: "defend"),
            .init(id: "defend_2", cardId: "defend"),
            .init(id: "defend_3", cardId: "defend"),
            .init(id: "strike_1", cardId: "strike"),
        ]

        let engine = BattleEngine(
            player: player,
            enemies: [enemy],
            deck: deck,
            relicManager: RelicManager(),
            seed: seed
        )

        engine.startBattle()

        let oldIntent = engine.state.enemies[0].plannedMove?.intent.text
        XCTAssertNotNil(oldIntent)

        guard let rewriteIndex = engine.state.hand.firstIndex(where: { $0.cardId == "fate_rewrite" }) else {
            return XCTFail("回合开始未抽到 命运改写")
        }

        engine.clearEvents()
        _ = engine.handleAction(.playCard(handIndex: rewriteIndex, targetEnemyIndex: 0))

        let newIntent = engine.state.enemies[0].plannedMove?.intent.text
        XCTAssertEqual(newIntent, "防御（被改写）")
        XCTAssertEqual(engine.state.player.statuses.stacks(of: "madness"), 2)
        XCTAssertTrue(engine.events.contains(where: {
            if case .intentRewritten(_, let old, let new) = $0 {
                return old == oldIntent && new == "防御（被改写）"
            }
            return false
        }))
    }
    func testForesight_picksFirstAttack_andPreservesOrderForOthers() {
        // 目标：预知 N 取出抽牌堆顶 N 张 -> 选 1 张入手（优先攻击牌） -> 其余按原顺序放回
        let seed: UInt64 = 1
        
        let player = createDefaultPlayer()
        let enemy = Entity(id: "e0", name: "测试敌人", maxHP: 50, enemyId: "shadow_stalker")
        
        // deck 洗牌是确定性的：我们在断言里用同一 RNG 复算初始牌堆顺序
        // 为避免“抽不到灵视/抽牌堆不足 N 张”的不稳定问题，这里放足够多张牌
        // 其中灵视很多张，确保回合开始手里一定能打出一张；同时抽牌堆里也会有攻击牌供预知选择。
        let deck: [Card] = [
            .init(id: "s1", cardId: "spirit_sight"),
            .init(id: "s2", cardId: "spirit_sight"),
            .init(id: "s3", cardId: "spirit_sight"),
            .init(id: "s4", cardId: "spirit_sight"),
            .init(id: "s5", cardId: "spirit_sight"),
            .init(id: "d1", cardId: "defend"),
            .init(id: "k1", cardId: "strike"),
            .init(id: "d2", cardId: "defend"),
            .init(id: "k2", cardId: "strike"),
            .init(id: "d3", cardId: "defend"),
            .init(id: "k3", cardId: "strike"),
        ]
        
        let engine = BattleEngine(
            player: player,
            enemies: [enemy],
            deck: deck,
            relicManager: RelicManager(),
            seed: seed
        )
        
        // 复算 BattleEngine 初始化后的抽牌堆（drawPile 末尾是顶部）
        let expectedDrawPile: [Card] = SeededRNG(seed: seed).shuffled(deck)
        
        engine.startBattle()
        
        // 回合开始已抽 5 张（从 drawPile.removeLast()）
        XCTAssertEqual(engine.state.hand.count, 5)
        
        // 找到灵视并打出
        let spiritSightIndex = engine.state.hand.firstIndex { $0.cardId == "spirit_sight" }
        XCTAssertNotNil(spiritSightIndex)
        _ = engine.handleAction(.playCard(handIndex: spiritSightIndex!, targetEnemyIndex: nil))
        
        // 预知 2：从 drawPile 顶部取 2 张（= drawPile 的 suffix(2) 的顶部优先）
        // 但要注意：开始战斗时抽了 5 张，所以我们需要在 expectedDrawPile 上模拟抽牌消耗。
        let afterDraw5 = Array(expectedDrawPile.dropLast(5))
        XCTAssertGreaterThanOrEqual(afterDraw5.count, 2)
        let top2 = Array(afterDraw5.suffix(2))                  // drawPile 顶部两张（顺序：从底到顶）
        let topCards = Array(top2.reversed())                   // applyForesight 内部转成 [顶部, 次顶]
        
        // 预期选择：topCards 中第一张攻击牌，否则第一张
        let chosen: Card = topCards.first(where: { CardRegistry.require($0.cardId).type == .attack }) ?? topCards[0]
        let unchosen: [Card] = topCards.filter { $0.id != chosen.id }
        
        // 手里应该新增 chosen
        XCTAssertTrue(engine.state.hand.contains(where: { $0.id == chosen.id }))
        
        // 未选中的应该按原顺序放回到抽牌堆顶部（末尾）
        // applyForesight 会把未选中的卡按 topCards 的原顺序放回，所以顶部应为：... unchosen(按 topCards 顺序)
        // 由于只有 1 张未选中，直接检查最后一张
        if let remaining = unchosen.first {
            XCTAssertEqual(engine.state.drawPile.last?.id, remaining.id)
        }
    }
    
    func testBrokenWatch_addsOneExtraCard_onlyOnFirstForesightEachTurn() {
        let seed: UInt64 = 2
        
        let player = createDefaultPlayer()
        let enemy = Entity(id: "e0", name: "测试敌人", maxHP: 80, enemyId: "shadow_stalker")
        
        // 放两张灵视，确保同一回合能打两次预知
        // 放多张灵视，确保同一回合能打出两次预知，且抽牌堆仍有足够卡用于 fromCount=3 的断言
        let deck: [Card] = [
            .init(id: "s1", cardId: "spirit_sight"),
            .init(id: "s2", cardId: "spirit_sight"),
            .init(id: "s3", cardId: "spirit_sight"),
            .init(id: "s4", cardId: "spirit_sight"),
            .init(id: "s5", cardId: "spirit_sight"),
            .init(id: "k1", cardId: "strike"),
            .init(id: "k2", cardId: "strike"),
            .init(id: "k3", cardId: "strike"),
            .init(id: "d1", cardId: "defend"),
            .init(id: "d2", cardId: "defend"),
            .init(id: "d3", cardId: "defend"),
            .init(id: "d4", cardId: "defend"),
        ]
        
        var relics = RelicManager()
        relics.add("broken_watch")
        
        let engine = BattleEngine(
            player: player,
            enemies: [enemy],
            deck: deck,
            relicManager: relics,
            seed: seed
        )
        
        engine.startBattle()
        
        // 打第一张灵视：预知 2 + 破碎怀表额外 +1 => 会触发一次 foresightChosen(fromCount: 3)
        if let idx1 = engine.state.hand.firstIndex(where: { $0.cardId == "spirit_sight" }) {
            _ = engine.handleAction(.playCard(handIndex: idx1, targetEnemyIndex: nil))
        } else {
            return XCTFail("回合开始未抽到灵视，seed/牌组不稳定")
        }
        
        XCTAssertTrue(engine.events.contains(where: {
            if case .foresightChosen(_, let fromCount) = $0 { return fromCount == 3 }
            return false
        }))
        
        engine.clearEvents()
        
        // 同回合第二次灵视：不应再 +1 => fromCount: 2
        if let idx2 = engine.state.hand.firstIndex(where: { $0.cardId == "spirit_sight" }) {
            _ = engine.handleAction(.playCard(handIndex: idx2, targetEnemyIndex: nil))
        } else {
            // 如果第二张不在手里，这个用例就不稳定；但通常 deck 里有两张且 cost=0，抽牌足够会出现
            return XCTFail("同回合未能再次抽到灵视用于验证破碎怀表的“每回合首次”限制")
        }
        
        XCTAssertTrue(engine.events.contains(where: {
            if case .foresightChosen(_, let fromCount) = $0 { return fromCount == 2 }
            return false
        }))
    }
}
