import XCTest
@testable import GameCore

/// 卡牌定义（CardDefinition）纯函数测试
///
/// 目的：
/// - 直接验证每张卡的 `play(snapshot:)` 是否产出**正确的 BattleEffect 列表**
/// - 防止“卡牌数值/状态写错但编译仍通过”的回归
final class CardDefinitionPlayTests: XCTestCase {
    private func makeSnapshot(energy: Int = 3) -> BattleSnapshot {
        let player = Entity(id: "player", name: "玩家", maxHP: 80)
        let enemy = Entity(id: "jaw_worm", name: "下颚虫", maxHP: 40, enemyId: "jaw_worm")
        return BattleSnapshot(turn: 1, player: player, enemy: enemy, energy: energy)
    }
    
    func testStrike_play_producesExpectedEffects() {
        let effects = Strike.play(snapshot: makeSnapshot())
        XCTAssertEqual(effects, [.dealDamage(target: .enemy, base: 6)])
    }
    
    func testStrikePlus_play_producesExpectedEffects() {
        let effects = StrikePlus.play(snapshot: makeSnapshot())
        XCTAssertEqual(effects, [.dealDamage(target: .enemy, base: 9)])
    }
    
    func testDefend_play_producesExpectedEffects() {
        let effects = Defend.play(snapshot: makeSnapshot())
        XCTAssertEqual(effects, [.gainBlock(target: .player, base: 5)])
    }
    
    func testDefendPlus_play_producesExpectedEffects() {
        let effects = DefendPlus.play(snapshot: makeSnapshot())
        XCTAssertEqual(effects, [.gainBlock(target: .player, base: 8)])
    }
    
    func testBash_play_producesExpectedEffects() {
        let effects = Bash.play(snapshot: makeSnapshot())
        XCTAssertEqual(
            effects,
            [
                .dealDamage(target: .enemy, base: 8),
                .applyStatus(target: .enemy, statusId: "vulnerable", stacks: 2)
            ]
        )
    }
    
    func testBashPlus_play_producesExpectedEffects() {
        let effects = BashPlus.play(snapshot: makeSnapshot())
        XCTAssertEqual(
            effects,
            [
                .dealDamage(target: .enemy, base: 10),
                .applyStatus(target: .enemy, statusId: "vulnerable", stacks: 3)
            ]
        )
    }
    
    func testPommelStrike_play_producesExpectedEffects() {
        let effects = PommelStrike.play(snapshot: makeSnapshot())
        XCTAssertEqual(
            effects,
            [
                .dealDamage(target: .enemy, base: 9),
                .drawCards(count: 1)
            ]
        )
    }
    
    func testShrugItOff_play_producesExpectedEffects() {
        let effects = ShrugItOff.play(snapshot: makeSnapshot())
        XCTAssertEqual(
            effects,
            [
                .gainBlock(target: .player, base: 8),
                .drawCards(count: 1)
            ]
        )
    }
    
    func testInflame_play_producesExpectedEffects() {
        let effects = Inflame.play(snapshot: makeSnapshot())
        XCTAssertEqual(
            effects,
            [
                .applyStatus(target: .player, statusId: "strength", stacks: 2)
            ]
        )
    }
    
    func testClothesline_play_producesExpectedEffects() {
        let effects = Clothesline.play(snapshot: makeSnapshot())
        XCTAssertEqual(
            effects,
            [
                .dealDamage(target: .enemy, base: 12),
                .applyStatus(target: .enemy, statusId: "weak", stacks: 2)
            ]
        )
    }
}


