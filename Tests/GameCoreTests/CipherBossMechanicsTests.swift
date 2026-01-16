import XCTest
@testable import GameCore

final class CipherBossMechanicsTests: XCTestCase {
    func testCipher_chooseMove_includesP6EffectsAcrossPhases() {
        let player = Entity(id: "player", name: LocalizedText("玩家", "玩家"), maxHP: 80)

        // Phase 1 (HP > 60%): turn 3 is “预知反制”
        do {
            var rng = SeededRNG(seed: 1)
            var cipher = Entity(id: "cipher", name: LocalizedText("赛弗", "赛弗"), maxHP: 100, enemyId: "cipher")
            cipher.currentHP = 100
            let snap = BattleSnapshot(turn: 3, player: player, enemies: [cipher], energy: 3)
            let move = Cipher.chooseMove(selfIndex: 0, snapshot: snap, rng: &rng)
            XCTAssertTrue(move.intent.text.zhHans.contains("预知反制"))
            XCTAssertTrue(move.effects.contains(.applyForesightPenaltyNextTurn(amount: 1)))
        }

        // Phase 2 (60% ≥ HP > 30%): turn 2 is “命运剥夺”
        do {
            var rng = SeededRNG(seed: 2)
            var cipher = Entity(id: "cipher", name: LocalizedText("赛弗", "赛弗"), maxHP: 100, enemyId: "cipher")
            cipher.currentHP = 50
            let snap = BattleSnapshot(turn: 2, player: player, enemies: [cipher], energy: 3)
            let move = Cipher.chooseMove(selfIndex: 0, snapshot: snap, rng: &rng)
            XCTAssertTrue(move.intent.text.zhHans.contains("命运剥夺"))
            XCTAssertTrue(move.effects.contains(.discardRandomHand(count: 2)))
            XCTAssertTrue(move.effects.contains(.applyStatus(target: .player, statusId: Madness.id, stacks: 2)))
        }

        // Phase 3 (HP ≤ 30%): turn 2 is “命运改写”，turn 3 is “时间回溯”
        do {
            var rng = SeededRNG(seed: 3)
            var cipher = Entity(id: "cipher", name: LocalizedText("赛弗", "赛弗"), maxHP: 100, enemyId: "cipher")
            cipher.currentHP = 30

            let t2 = BattleSnapshot(turn: 2, player: player, enemies: [cipher], energy: 3)
            let m2 = Cipher.chooseMove(selfIndex: 0, snapshot: t2, rng: &rng)
            XCTAssertTrue(m2.intent.text.zhHans.contains("命运改写"))
            XCTAssertTrue(m2.effects.contains(.applyFirstCardCostIncreaseNextTurn(amount: 1)))

            let t3 = BattleSnapshot(turn: 3, player: player, enemies: [cipher], energy: 3)
            let m3 = Cipher.chooseMove(selfIndex: 0, snapshot: t3, rng: &rng)
            XCTAssertTrue(m3.intent.text.zhHans.contains("时间回溯"))
            XCTAssertTrue(m3.effects.contains(.enemyHeal(enemyIndex: 0, amount: 15)))
        }
    }

    func testCipher_foresightPenaltyNextTurn_reducesForesightCountNextTurn() {
        // 目标：赛弗在阶段 1 的“预知反制”会让下回合预知数量 -1（最低为 0）
        let seed: UInt64 = 1
        let player = createDefaultPlayer()

        var cipher = Entity(id: "cipher", name: LocalizedText("赛弗", "赛弗"), maxHP: 100, enemyId: "cipher")
        cipher.currentHP = 100 // Phase 1

        // 牌组全部是灵视，保证下一回合一定能打出预知牌
        let deck: [Card] = (1...15).map { i in
            Card(id: "s\(i)", cardId: "spirit_sight")
        }

        let engine = BattleEngine(
            player: player,
            enemies: [cipher],
            deck: deck,
            relicManager: RelicManager(),
            seed: seed
        )
        engine.startBattle()

        // 让赛弗走到 turn 3 的“预知反制”并执行（玩家连续结束回合即可）
        _ = engine.handleAction(.endTurn) // enemy turn 1
        _ = engine.handleAction(.endTurn) // enemy turn 2
        _ = engine.handleAction(.endTurn) // enemy turn 3: applies penalty for next turn

        // turn 4：打出灵视（预知 2），应被惩罚为预知 1
        guard let idx = engine.state.hand.firstIndex(where: { $0.cardId == "spirit_sight" }) else {
            return XCTFail("期望回合 4 手牌中存在 灵视")
        }

        engine.clearEvents()
        _ = engine.handleAction(PlayerAction.playCard(handIndex: idx, targetEnemyIndex: nil))

        // 预知需要先完成选择，才能产生 foresightChosen 事件
        guard case .some(.foresight(_, let fromCount)) = engine.pendingInput else {
            return XCTFail("期望打出 灵视 后进入 pending foresight")
        }
        XCTAssertEqual(fromCount, 1)

        engine.clearEvents()
        _ = engine.submitForesightChoice(index: 0)

        XCTAssertTrue(engine.events.contains(where: { event in
            if case .foresightChosen(_, let c) = event { return c == 1 }
            return false
        }))
    }

    func testCipher_firstCardCostIncreaseNextTurn_appliesOnlyToFirstCard() {
        // 目标：赛弗“命运改写”会让下回合第一张牌费用 +1，且只生效一次
        let seed: UInt64 = 2
        let player = createDefaultPlayer()

        var cipher = Entity(id: "cipher", name: LocalizedText("赛弗", "赛弗"), maxHP: 100, enemyId: "cipher")
        cipher.currentHP = 30 // Phase 3

        // 牌组全部是灵视（cost=0），便于验证“首牌费用 +1”会让 played.cost 变为 1
        let deck: [Card] = (1...20).map { i in
            Card(id: "s\(i)", cardId: "spirit_sight")
        }

        let engine = BattleEngine(
            player: player,
            enemies: [cipher],
            deck: deck,
            relicManager: RelicManager(),
            seed: seed
        )
        engine.startBattle()

        // turn 1：结束回合，赛弗执行“绝望之击”
        _ = engine.handleAction(.endTurn)
        // turn 2：结束回合，赛弗执行“命运改写”（设置下回合首牌费用 +1）
        _ = engine.handleAction(.endTurn)

        // turn 3：首张牌费用应 +1
        guard let first = engine.state.hand.firstIndex(where: { $0.cardId == "spirit_sight" }) else {
            return XCTFail("期望回合 3 手牌中存在 灵视")
        }

        engine.clearEvents()
        _ = engine.handleAction(PlayerAction.playCard(handIndex: first, targetEnemyIndex: nil))
        XCTAssertTrue(engine.events.contains { event in
            guard case let .played(_, cardId, cost) = event else { return false }
            return cardId == "spirit_sight" && cost == 1
        })

        let energyAfterFirst = engine.state.energy
        XCTAssertEqual(energyAfterFirst, 2)

        // 完成预知选择，解除 pending，才能继续出牌
        if case .some(.foresight) = engine.pendingInput {
            _ = engine.submitForesightChoice(index: 0)
        }

        // 同回合第二张灵视不应再加费
        guard let second = engine.state.hand.firstIndex(where: { $0.cardId == "spirit_sight" }) else {
            return XCTFail("期望回合 3 能继续打出第二张 灵视")
        }

        engine.clearEvents()
        _ = engine.handleAction(PlayerAction.playCard(handIndex: second, targetEnemyIndex: nil))
        XCTAssertTrue(engine.events.contains { event in
            guard case let .played(_, cardId, cost) = event else { return false }
            return cardId == "spirit_sight" && cost == 0
        })
        XCTAssertEqual(engine.state.energy, energyAfterFirst)
    }
}
