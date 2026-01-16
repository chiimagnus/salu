import XCTest
import GameCore

final class SeerAdvancedCardsTests: XCTestCase {
    func testPurificationRitual_clearsAllMadness_andDiscardsOneCard() {
        let seed: UInt64 = 1

        var player = createDefaultPlayer()
        player.statuses.set(Madness.id, stacks: 5)

        let enemy = Entity(id: "e0", name: LocalizedText("测试敌人", "测试敌人"), maxHP: 80, enemyId: "shadow_stalker")

        // deck=5：回合开始手里一定包含净化仪式与可弃置的其他牌
        let deck: [Card] = [
            .init(id: "p1", cardId: PurificationRitual.id),
            .init(id: "s1", cardId: SpiritSight.id),
            .init(id: "s2", cardId: SpiritSight.id),
            .init(id: "d1", cardId: Defend.id),
            .init(id: "k1", cardId: Strike.id),
        ]

        let engine = BattleEngine(
            player: player,
            enemies: [enemy],
            deck: deck,
            relicManager: RelicManager(),
            seed: seed
        )
        engine.startBattle()

        let handCountBefore = engine.state.hand.count
        let discardCountBefore = engine.state.discardPile.count
        XCTAssertEqual(engine.state.player.statuses.stacks(of: Madness.id), 5)

        guard let idx = engine.state.hand.firstIndex(where: { $0.cardId == PurificationRitual.id }) else {
            return XCTFail("回合开始未抽到 净化仪式")
        }

        engine.clearEvents()
        _ = engine.handleAction(PlayerAction.playCard(handIndex: idx, targetEnemyIndex: nil))

        XCTAssertEqual(engine.state.player.statuses.stacks(of: Madness.id), 0)
        XCTAssertEqual(engine.state.hand.count, handCountBefore - 2) // 打出 1 张 + 随机弃 1 张
        XCTAssertEqual(engine.state.discardPile.count, discardCountBefore + 2)
        XCTAssertTrue(engine.events.contains { event in
            if case .madnessCleared(let amount) = event { return amount == 5 }
            return false
        })
        XCTAssertTrue(engine.events.contains { event in
            if case .handDiscarded(let count) = event { return count == 1 }
            return false
        })
    }

    func testPurificationRitualPlus_clearsAllMadness_withoutDiscard() {
        let seed: UInt64 = 2

        var player = createDefaultPlayer()
        player.statuses.set(Madness.id, stacks: 3)

        let enemy = Entity(id: "e0", name: LocalizedText("测试敌人", "测试敌人"), maxHP: 80, enemyId: "shadow_stalker")

        let deck: [Card] = [
            .init(id: "p1", cardId: PurificationRitualPlus.id),
            .init(id: "d1", cardId: Defend.id),
            .init(id: "d2", cardId: Defend.id),
            .init(id: "k1", cardId: Strike.id),
            .init(id: "k2", cardId: Strike.id),
        ]

        let engine = BattleEngine(
            player: player,
            enemies: [enemy],
            deck: deck,
            relicManager: RelicManager(),
            seed: seed
        )
        engine.startBattle()

        let handCountBefore = engine.state.hand.count
        let discardCountBefore = engine.state.discardPile.count

        guard let idx = engine.state.hand.firstIndex(where: { $0.cardId == PurificationRitualPlus.id }) else {
            return XCTFail("回合开始未抽到 净化仪式+")
        }

        engine.clearEvents()
        _ = engine.handleAction(PlayerAction.playCard(handIndex: idx, targetEnemyIndex: nil))

        XCTAssertEqual(engine.state.player.statuses.stacks(of: Madness.id), 0)
        XCTAssertEqual(engine.state.hand.count, handCountBefore - 1) // 仅打出自身
        XCTAssertEqual(engine.state.discardPile.count, discardCountBefore + 1)
        XCTAssertTrue(engine.events.contains { event in
            if case .madnessCleared(let amount) = event { return amount == 3 }
            return false
        })
        XCTAssertFalse(engine.events.contains { event in
            if case .handDiscarded(let count) = event { return count == 1 }
            return false
        })
    }

    func testProphecyEcho_dealsDamageBasedOnForesightCountThisTurn() {
        let seed: UInt64 = 3

        let player = createDefaultPlayer()
        let enemy = Entity(id: "e0", name: LocalizedText("测试敌人", "测试敌人"), maxHP: 200, enemyId: "shadow_stalker")

        // deck=7：回合开始抽 5，抽牌堆仍剩 2 张，保证同回合能进行 2 次预知（第 2 次可能只有 1 张可看）
        // 组合保证：回合开始手里至少有 2 张灵视 + 1 张预言回响
        let deck: [Card] = [
            .init(id: "ss1", cardId: SpiritSight.id),
            .init(id: "ss2", cardId: SpiritSight.id),
            .init(id: "ss3", cardId: SpiritSight.id),
            .init(id: "ss4", cardId: SpiritSight.id),
            .init(id: "pe1", cardId: ProphecyEcho.id),
            .init(id: "pe2", cardId: ProphecyEcho.id),
            .init(id: "pe3", cardId: ProphecyEcho.id),
        ]

        let engine = BattleEngine(
            player: player,
            enemies: [enemy],
            deck: deck,
            relicManager: RelicManager(),
            seed: seed
        )
        engine.startBattle()

        // 先打两次预知（灵视）
        for _ in 0..<2 {
            guard let idx = engine.state.hand.firstIndex(where: { $0.cardId == SpiritSight.id }) else {
                return XCTFail("同回合未能找到 灵视 用于预知次数堆叠")
            }
            _ = engine.handleAction(PlayerAction.playCard(handIndex: idx, targetEnemyIndex: nil))
            // 预知需要完成选择后才能继续出牌
            if case .some(.foresight) = engine.pendingInput {
                _ = engine.submitForesightChoice(index: 0)
            }
        }

        guard let echoIdx = engine.state.hand.firstIndex(where: { $0.cardId == ProphecyEcho.id }) else {
            return XCTFail("同回合未能找到 预言回响")
        }

        let hpBefore = engine.state.enemies[0].currentHP
        engine.clearEvents()
        _ = engine.handleAction(PlayerAction.playCard(handIndex: echoIdx, targetEnemyIndex: 0))
        let hpAfter = engine.state.enemies[0].currentHP

        XCTAssertEqual(hpBefore - hpAfter, 6) // 3 × 本回合预知次数(2)
    }

    func testSequenceResonance_grantsBlockAfterForesight() {
        let seed: UInt64 = 4

        let player = createDefaultPlayer()
        let enemy = Entity(id: "e0", name: LocalizedText("测试敌人", "测试敌人"), maxHP: 80, enemyId: "shadow_stalker")

        // deck=6：回合开始抽 5，抽牌堆仍剩 1 张，保证预知至少能触发一次
        let deck: [Card] = [
            .init(id: "sr1", cardId: SequenceResonanceCard.id),
            .init(id: "sr2", cardId: SequenceResonanceCard.id),
            .init(id: "ss1", cardId: SpiritSight.id),
            .init(id: "ss2", cardId: SpiritSight.id),
            .init(id: "d1", cardId: Defend.id),
            .init(id: "d2", cardId: Defend.id),
        ]

        let engine = BattleEngine(
            player: player,
            enemies: [enemy],
            deck: deck,
            relicManager: RelicManager(),
            seed: seed
        )
        engine.startBattle()

        XCTAssertEqual(engine.state.player.block, 0)

        guard let srIdx = engine.state.hand.firstIndex(where: { $0.cardId == SequenceResonanceCard.id }) else {
            return XCTFail("回合开始未抽到 序列共鸣")
        }
        _ = engine.handleAction(PlayerAction.playCard(handIndex: srIdx, targetEnemyIndex: nil))

        guard let ssIdx = engine.state.hand.firstIndex(where: { $0.cardId == SpiritSight.id }) else {
            return XCTFail("回合开始未抽到 灵视（用于触发预知）")
        }
        _ = engine.handleAction(PlayerAction.playCard(handIndex: ssIdx, targetEnemyIndex: nil))

        if case .some(.foresight) = engine.pendingInput {
            _ = engine.submitForesightChoice(index: 0)
        }
        XCTAssertEqual(engine.state.player.block, 1)
    }

    func testSequenceResonancePlus_grantsMoreBlockAfterForesight() {
        let seed: UInt64 = 5

        let player = createDefaultPlayer()
        let enemy = Entity(id: "e0", name: LocalizedText("测试敌人", "测试敌人"), maxHP: 80, enemyId: "shadow_stalker")

        let deck: [Card] = [
            .init(id: "sr1", cardId: SequenceResonanceCardPlus.id),
            .init(id: "sr2", cardId: SequenceResonanceCardPlus.id),
            .init(id: "ss1", cardId: SpiritSight.id),
            .init(id: "ss2", cardId: SpiritSight.id),
            .init(id: "d1", cardId: Defend.id),
            .init(id: "d2", cardId: Defend.id),
        ]

        let engine = BattleEngine(
            player: player,
            enemies: [enemy],
            deck: deck,
            relicManager: RelicManager(),
            seed: seed
        )
        engine.startBattle()

        guard let srIdx = engine.state.hand.firstIndex(where: { $0.cardId == SequenceResonanceCardPlus.id }) else {
            return XCTFail("回合开始未抽到 序列共鸣+")
        }
        _ = engine.handleAction(PlayerAction.playCard(handIndex: srIdx, targetEnemyIndex: nil))

        guard let ssIdx = engine.state.hand.firstIndex(where: { $0.cardId == SpiritSight.id }) else {
            return XCTFail("回合开始未抽到 灵视（用于触发预知）")
        }
        _ = engine.handleAction(PlayerAction.playCard(handIndex: ssIdx, targetEnemyIndex: nil))

        if case .some(.foresight) = engine.pendingInput {
            _ = engine.submitForesightChoice(index: 0)
        }
        XCTAssertEqual(engine.state.player.block, 2)
    }

    func testSequenceResonance_stacksAcrossMultiplePlays_grantsMoreBlock() {
        let seed: UInt64 = 6

        let player = createDefaultPlayer()
        let enemy = Entity(id: "e0", name: LocalizedText("测试敌人", "测试敌人"), maxHP: 200, enemyId: "shadow_stalker")

        // deck=6：每回合抽 5，抽牌堆保证至少剩 1 张，让预知必定可触发
        // 使用 3×序列共鸣 + 3×灵视，避免因洗牌导致缺牌（无论遗漏哪一张，手牌都必含 SR 与 SS）
        let deck: [Card] = [
            .init(id: "sr1", cardId: SequenceResonanceCard.id),
            .init(id: "sr2", cardId: SequenceResonanceCard.id),
            .init(id: "sr3", cardId: SequenceResonanceCard.id),
            .init(id: "ss1", cardId: SpiritSight.id),
            .init(id: "ss2", cardId: SpiritSight.id),
            .init(id: "ss3", cardId: SpiritSight.id),
        ]

        let engine = BattleEngine(
            player: player,
            enemies: [enemy],
            deck: deck,
            relicManager: RelicManager(),
            seed: seed
        )
        engine.startBattle()

        // Turn 1: 打出 1 次序列共鸣 + 触发 1 次预知 → 应获得 1 点格挡
        guard let sr1 = engine.state.hand.firstIndex(where: { $0.cardId == SequenceResonanceCard.id }) else {
            return XCTFail("回合开始未抽到 序列共鸣")
        }
        _ = engine.handleAction(PlayerAction.playCard(handIndex: sr1, targetEnemyIndex: nil))

        guard let ss1 = engine.state.hand.firstIndex(where: { $0.cardId == SpiritSight.id }) else {
            return XCTFail("回合开始未抽到 灵视（用于触发预知）")
        }
        let blockBefore1 = engine.state.player.block
        _ = engine.handleAction(PlayerAction.playCard(handIndex: ss1, targetEnemyIndex: nil))
        if case .some(.foresight) = engine.pendingInput {
            _ = engine.submitForesightChoice(index: 0)
        }
        let gained1 = engine.state.player.block - blockBefore1
        XCTAssertEqual(gained1, 1)

        // 结束回合，进入 Turn 2
        _ = engine.handleAction(.endTurn)

        // Turn 2: 再打出 1 次序列共鸣（应叠加 stacks）+ 触发 1 次预知 → 应获得 2 点格挡
        guard let sr2 = engine.state.hand.firstIndex(where: { $0.cardId == SequenceResonanceCard.id }) else {
            return XCTFail("第 2 回合未抽到 序列共鸣")
        }
        _ = engine.handleAction(PlayerAction.playCard(handIndex: sr2, targetEnemyIndex: nil))

        guard let ss2 = engine.state.hand.firstIndex(where: { $0.cardId == SpiritSight.id }) else {
            return XCTFail("第 2 回合未抽到 灵视（用于触发预知）")
        }
        let blockBefore2 = engine.state.player.block
        _ = engine.handleAction(PlayerAction.playCard(handIndex: ss2, targetEnemyIndex: nil))
        if case .some(.foresight) = engine.pendingInput {
            _ = engine.submitForesightChoice(index: 0)
        }
        let gained2 = engine.state.player.block - blockBefore2
        XCTAssertEqual(gained2, 2)
    }
}
