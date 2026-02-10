import XCTest
@testable import GameCore

/// BattleEngine 关键流程（集成级）测试
///
/// 目的：
/// - 覆盖 BattleEngine 中最容易回归的分支逻辑（能量不足、越界索引、弃牌洗牌、状态递减、战斗结束等）
/// - 确保核心回合管线（startBattle / endTurn / nextTurn）不会因为重构而“悄悄变错”
final class BattleEngineFlowTests: XCTestCase {
    private func makeStrikeDeck(count: Int) -> [Card] {
        (1...count).map { i in Card(id: "strike_\(i)", cardId: "strike") }
    }
    
    private func makeEngine(
        player: Entity = Entity(id: "player", name: LocalizedText("玩家", "玩家"), maxHP: 80),
        enemy: Entity = Entity(id: "enemy", name: LocalizedText("敌人", "敌人"), maxHP: 999),
        deck: [Card],
        seed: UInt64 = 1
    ) -> BattleEngine {
        BattleEngine(player: player, enemies: [enemy], deck: deck, seed: seed)
    }
    
    func testPlayCardsUntilEnergyZero_thenNotEnoughEnergyEventEmitted() {
    
        print("🧪 测试：testPlayCardsUntilEnergyZero_thenNotEnoughEnergyEventEmitted")
        let engine = makeEngine(deck: makeStrikeDeck(count: 5))
        engine.startBattle()
        engine.clearEvents()
        
        // 初始能量为 3：连续打出 3 张 Strike 应当成功
        XCTAssertTrue(engine.handleAction(PlayerAction.playCard(handIndex: 0, targetEnemyIndex: 0)))
        XCTAssertTrue(engine.handleAction(PlayerAction.playCard(handIndex: 0, targetEnemyIndex: 0)))
        XCTAssertTrue(engine.handleAction(PlayerAction.playCard(handIndex: 0, targetEnemyIndex: 0)))
        XCTAssertEqual(engine.state.energy, 0)
        
        // 能量耗尽后再出牌，应提示能量不足并失败
        XCTAssertFalse(engine.handleAction(PlayerAction.playCard(handIndex: 0, targetEnemyIndex: 0)))
        XCTAssertTrue(
            engine.events.contains(.notEnoughEnergy(required: 1, available: 0)),
            "期望出现 notEnoughEnergy 事件，避免 UI 层只能靠字符串判断"
        )
    }
    
    func testInvalidHandIndex_emitsInvalidAction() {
    
        print("🧪 测试：testInvalidHandIndex_emitsInvalidAction")
        let engine = makeEngine(deck: makeStrikeDeck(count: 1))
        engine.startBattle()
        engine.clearEvents()
        
        XCTAssertFalse(engine.handleAction(PlayerAction.playCard(handIndex: 999, targetEnemyIndex: 0)))
        XCTAssertTrue(engine.events.contains(.invalidAction(
            reason: LocalizedText("无效的卡牌索引", "Invalid card index")
        )))
    }

    func testPlayAttackCard_requiresTarget_whenMultipleEnemiesAlive() {

        print("🧪 测试：testPlayAttackCard_requiresTarget_whenMultipleEnemiesAlive")
        let player = Entity(id: "player", name: LocalizedText("玩家", "玩家"), maxHP: 80)
        let e1 = Entity(id: "e1", name: LocalizedText("敌人A", "敌人A"), maxHP: 999, enemyId: "jaw_worm")
        let e2 = Entity(id: "e2", name: LocalizedText("敌人B", "敌人B"), maxHP: 999, enemyId: "jaw_worm")
        let engine = BattleEngine(
            player: player,
            enemies: [e1, e2],
            deck: [Card(id: "strike_1", cardId: "strike")],
            seed: 1
        )
        engine.startBattle()
        engine.clearEvents()

        let energyBefore = engine.state.energy
        let handCountBefore = engine.state.hand.count
        let e1HPBefore = engine.state.enemies[0].currentHP
        let e2HPBefore = engine.state.enemies[1].currentHP

        XCTAssertFalse(engine.handleAction(PlayerAction.playCard(handIndex: 0, targetEnemyIndex: nil)))
        XCTAssertTrue(engine.events.contains(.invalidAction(
            reason: LocalizedText("该牌需要选择目标", "This card requires a target")
        )))

        // 失败不应消耗能量/移除手牌/造成伤害
        XCTAssertEqual(engine.state.energy, energyBefore)
        XCTAssertEqual(engine.state.hand.count, handCountBefore)
        XCTAssertEqual(engine.state.enemies[0].currentHP, e1HPBefore)
        XCTAssertEqual(engine.state.enemies[1].currentHP, e2HPBefore)
    }

    func testPlayAttackCard_targetsCorrectEnemyIndex_whenMultipleEnemiesAlive() {

        print("🧪 测试：testPlayAttackCard_targetsCorrectEnemyIndex_whenMultipleEnemiesAlive")
        let player = Entity(id: "player", name: LocalizedText("玩家", "玩家"), maxHP: 80)
        let e1 = Entity(id: "e1", name: LocalizedText("敌人A", "敌人A"), maxHP: 999, enemyId: "jaw_worm")
        let e2 = Entity(id: "e2", name: LocalizedText("敌人B", "敌人B"), maxHP: 999, enemyId: "jaw_worm")
        let engine = BattleEngine(
            player: player,
            enemies: [e1, e2],
            deck: [Card(id: "strike_1", cardId: "strike")],
            seed: 1
        )
        engine.startBattle()
        engine.clearEvents()

        let e1HPBefore = engine.state.enemies[0].currentHP
        let e2HPBefore = engine.state.enemies[1].currentHP

        XCTAssertTrue(engine.handleAction(PlayerAction.playCard(handIndex: 0, targetEnemyIndex: 1)))
        XCTAssertEqual(engine.state.enemies[0].currentHP, e1HPBefore)
        XCTAssertEqual(engine.state.enemies[1].currentHP, e2HPBefore - 6)
    }
    
    func testShuffleDiscardIntoDraw_emitsShuffledEvent_nextTurn() {
    
        print("🧪 测试：testShuffleDiscardIntoDraw_emitsShuffledEvent_nextTurn")
        // 使用“无 enemyId 的敌人”避免敌人 AI/效果干扰：plannedMove = 空 effects
        let enemy = Entity(id: "enemy", name: LocalizedText("木桩", "木桩"), maxHP: 999)
        let engine = makeEngine(enemy: enemy, deck: makeStrikeDeck(count: 5))
        engine.startBattle()
        engine.clearEvents()
        
        // 结束回合：手牌会进入弃牌堆，下一回合抽牌时应触发洗牌
        XCTAssertTrue(engine.handleAction(.endTurn))
        
        XCTAssertTrue(
            engine.events.contains(.shuffled(count: 5)),
            "期望在下一回合抽牌时触发 shuffled 事件（弃牌堆洗回抽牌堆）"
        )
        XCTAssertEqual(engine.state.turn, 2)
    }
    
    func testBattleEnd_emitsBattleWon_andSubsequentActionIsInvalid() {
    
        print("🧪 测试：testBattleEnd_emitsBattleWon_andSubsequentActionIsInvalid")
        let player = Entity(id: "player", name: LocalizedText("玩家", "玩家"), maxHP: 80)
        let enemy = Entity(id: "enemy", name: LocalizedText("木桩", "木桩"), maxHP: 1)
        let engine = makeEngine(player: player, enemy: enemy, deck: [Card(id: "strike_1", cardId: "strike")])
        
        engine.startBattle()
        engine.clearEvents()
        
        XCTAssertTrue(engine.handleAction(PlayerAction.playCard(handIndex: 0, targetEnemyIndex: 0)))
        XCTAssertTrue(engine.state.isOver)
        XCTAssertEqual(engine.state.playerWon, true)
        XCTAssertTrue(engine.events.contains(.battleWon))
        
        // 战斗结束后继续操作应失败
        engine.clearEvents()
        XCTAssertFalse(engine.handleAction(.endTurn))
        XCTAssertTrue(engine.events.contains(.invalidAction(
            reason: LocalizedText("战斗已结束", "The battle is already over")
        )))
    }
    
    func testStatusDecay_turnEnd_decrementsAndEmitsExpiredEvent() {
    
        print("🧪 测试：testStatusDecay_turnEnd_decrementsAndEmitsExpiredEvent")
        var player = Entity(id: "player", name: LocalizedText("玩家", "玩家"), maxHP: 80)
        player.statuses.set("vulnerable", stacks: 1)
        
        let enemy = Entity(id: "enemy", name: LocalizedText("木桩", "木桩"), maxHP: 999)
        let engine = makeEngine(player: player, enemy: enemy, deck: makeStrikeDeck(count: 5))
        
        engine.startBattle()
        engine.clearEvents()
        
        XCTAssertTrue(engine.handleAction(.endTurn))
        
        XCTAssertEqual(engine.state.player.statuses.stacks(of: "vulnerable"), 0)
        XCTAssertTrue(
            engine.events.contains(.statusExpired(
                targetEntityId: "player",
                target: LocalizedText("玩家", "玩家"),
                effect: Vulnerable.name
            )),
            "期望 vulnerable 在回合结束递减到 0 后发出 statusExpired"
        )
    }
    
    func testPoisonOnTurnEnd_dealsDamageAndDecays() {
    
        print("🧪 测试：testPoisonOnTurnEnd_dealsDamageAndDecays")
        var player = Entity(id: "player", name: LocalizedText("玩家", "玩家"), maxHP: 80)
        player.statuses.set("poison", stacks: 2)
        
        let enemy = Entity(id: "enemy", name: LocalizedText("木桩", "木桩"), maxHP: 999)
        let engine = makeEngine(player: player, enemy: enemy, deck: makeStrikeDeck(count: 1))
        
        engine.startBattle()
        engine.clearEvents()
        
        let hpBefore = engine.state.player.currentHP
        XCTAssertTrue(engine.handleAction(.endTurn))
        
        // 中毒：回合结束造成等同层数的伤害（此处为 2）
        XCTAssertEqual(engine.state.player.currentHP, hpBefore - 2)
        // 中毒：回合结束递减 1
        XCTAssertEqual(engine.state.player.statuses.stacks(of: "poison"), 1)
    }
}
