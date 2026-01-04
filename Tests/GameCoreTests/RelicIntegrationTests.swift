import XCTest
@testable import GameCore

final class RelicIntegrationTests: XCTestCase {
    func testLanternBattleStartAddsEnergyWithoutBeingOverwritten() {
        // 给玩家灯笼：战斗开始 +1 能量
        var relics = RelicManager()
        relics.add("lantern")
        
        let player = Entity(id: "player", name: "玩家", maxHP: 80)
        let enemy = Entity(id: "jaw_worm", name: "下颚虫", maxHP: 1, enemyId: "jaw_worm")
        let deck = [Card(id: "strike_1", cardId: "strike")]
        
        let engine = BattleEngine(player: player, enemy: enemy, deck: deck, relicManager: relics, seed: 1)
        engine.startBattle()
        
        // 默认 maxEnergy=3，灯笼应在第 1 回合开始后把能量提升到 4
        XCTAssertEqual(engine.state.energy, 4)
    }
    
    func testBurningBloodHealsOnBattleWin() {
        var relics = RelicManager()
        relics.add("burning_blood")
        
        var player = Entity(id: "player", name: "玩家", maxHP: 80)
        player.currentHP = 50
        
        let enemy = Entity(id: "jaw_worm", name: "下颚虫", maxHP: 1, enemyId: "jaw_worm")
        let deck = [Card(id: "strike_1", cardId: "strike")]
        
        let engine = BattleEngine(player: player, enemy: enemy, deck: deck, relicManager: relics, seed: 1)
        engine.startBattle()
        
        // 打出 Strike 直接击杀
        _ = engine.handleAction(.playCard(handIndex: 0))
        
        XCTAssertTrue(engine.state.isOver)
        XCTAssertEqual(engine.state.playerWon, true)
        
        // 战斗胜利后燃烧之血恢复 6 HP
        XCTAssertEqual(engine.state.player.currentHP, 56)
    }
}


