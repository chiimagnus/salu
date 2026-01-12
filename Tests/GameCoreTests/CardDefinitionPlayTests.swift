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
        return BattleSnapshot(turn: 1, player: player, enemies: [enemy], energy: energy)
    }
    
    private func makeSnapshotWithTwoEnemies(energy: Int = 3) -> BattleSnapshot {
        let player = Entity(id: "player", name: "玩家", maxHP: 80)
        let e1 = Entity(id: "e1", name: "敌人A", maxHP: 40, enemyId: "jaw_worm")
        let e2 = Entity(id: "e2", name: "敌人B", maxHP: 40, enemyId: "jaw_worm")
        return BattleSnapshot(turn: 1, player: player, enemies: [e1, e2], energy: energy)
    }
    
    func testStrike_play_producesExpectedEffects() {
    
        print("🧪 测试：testStrike_play_producesExpectedEffects")
        let effects = Strike.play(snapshot: makeSnapshot(), targetEnemyIndex: 0)
        XCTAssertEqual(effects, [.dealDamage(source: .player, target: .enemy(index: 0), base: 6)])
    }
    
    func testStrikePlus_play_producesExpectedEffects() {
    
        print("🧪 测试：testStrikePlus_play_producesExpectedEffects")
        let effects = StrikePlus.play(snapshot: makeSnapshot(), targetEnemyIndex: 0)
        XCTAssertEqual(effects, [.dealDamage(source: .player, target: .enemy(index: 0), base: 9)])
    }
    
    func testDefend_play_producesExpectedEffects() {
    
        print("🧪 测试：testDefend_play_producesExpectedEffects")
        let effects = Defend.play(snapshot: makeSnapshot(), targetEnemyIndex: nil)
        XCTAssertEqual(effects, [.gainBlock(target: .player, base: 5)])
    }
    
    func testDefendPlus_play_producesExpectedEffects() {
    
        print("🧪 测试：testDefendPlus_play_producesExpectedEffects")
        let effects = DefendPlus.play(snapshot: makeSnapshot(), targetEnemyIndex: nil)
        XCTAssertEqual(effects, [.gainBlock(target: .player, base: 8)])
    }
    
    func testBash_play_producesExpectedEffects() {
    
        print("🧪 测试：testBash_play_producesExpectedEffects")
        let effects = Bash.play(snapshot: makeSnapshot(), targetEnemyIndex: 0)
        XCTAssertEqual(
            effects,
            [
                .dealDamage(source: .player, target: .enemy(index: 0), base: 8),
                .applyStatus(target: .enemy(index: 0), statusId: "vulnerable", stacks: 2)
            ]
        )
    }
    
    func testBashPlus_play_producesExpectedEffects() {
    
        print("🧪 测试：testBashPlus_play_producesExpectedEffects")
        let effects = BashPlus.play(snapshot: makeSnapshot(), targetEnemyIndex: 0)
        XCTAssertEqual(
            effects,
            [
                .dealDamage(source: .player, target: .enemy(index: 0), base: 10),
                .applyStatus(target: .enemy(index: 0), statusId: "vulnerable", stacks: 3)
            ]
        )
    }
    
    func testPommelStrike_play_producesExpectedEffects() {
    
        print("🧪 测试：testPommelStrike_play_producesExpectedEffects")
        let effects = PommelStrike.play(snapshot: makeSnapshot(), targetEnemyIndex: 0)
        XCTAssertEqual(
            effects,
            [
                .dealDamage(source: .player, target: .enemy(index: 0), base: 9),
                .drawCards(count: 1)
            ]
        )
    }
    
    func testShrugItOff_play_producesExpectedEffects() {
    
        print("🧪 测试：testShrugItOff_play_producesExpectedEffects")
        let effects = ShrugItOff.play(snapshot: makeSnapshot(), targetEnemyIndex: nil)
        XCTAssertEqual(
            effects,
            [
                .gainBlock(target: .player, base: 8),
                .drawCards(count: 1)
            ]
        )
    }
    
    func testInflame_play_producesExpectedEffects() {
    
        print("🧪 测试：testInflame_play_producesExpectedEffects")
        let effects = Inflame.play(snapshot: makeSnapshot(), targetEnemyIndex: nil)
        XCTAssertEqual(
            effects,
            [
                .applyStatus(target: .player, statusId: "strength", stacks: 2)
            ]
        )
    }
    
    func testClothesline_play_producesExpectedEffects() {
    
        print("🧪 测试：testClothesline_play_producesExpectedEffects")
        let effects = Clothesline.play(snapshot: makeSnapshot(), targetEnemyIndex: 0)
        XCTAssertEqual(
            effects,
            [
                .dealDamage(source: .player, target: .enemy(index: 0), base: 12),
                .applyStatus(target: .enemy(index: 0), statusId: "weak", stacks: 2)
            ]
        )
    }
    
    func testCleave_play_producesExpectedEffects() {
    
        print("🧪 测试：testCleave_play_producesExpectedEffects")
        let effects = Cleave.play(snapshot: makeSnapshotWithTwoEnemies(), targetEnemyIndex: nil)
        XCTAssertEqual(
            effects,
            [
                .dealDamage(source: .player, target: .enemy(index: 0), base: 4),
                .dealDamage(source: .player, target: .enemy(index: 1), base: 4),
            ]
        )
    }
    
    func testIntimidate_play_producesExpectedEffects() {
    
        print("🧪 测试：testIntimidate_play_producesExpectedEffects")
        let effects = Intimidate.play(snapshot: makeSnapshotWithTwoEnemies(), targetEnemyIndex: nil)
        XCTAssertEqual(
            effects,
            [
                .applyStatus(target: .enemy(index: 0), statusId: "weak", stacks: 2),
                .applyStatus(target: .enemy(index: 1), statusId: "weak", stacks: 2),
            ]
        )
    }
    
    func testAgileStance_play_producesExpectedEffects() {
    
        print("🧪 测试：testAgileStance_play_producesExpectedEffects")
        let effects = AgileStance.play(snapshot: makeSnapshot(), targetEnemyIndex: nil)
        XCTAssertEqual(
            effects,
            [
                .applyStatus(target: .player, statusId: "dexterity", stacks: 1)
            ]
        )
    }
    
    func testPoisonedStrike_play_producesExpectedEffects() {
    
        print("🧪 测试：testPoisonedStrike_play_producesExpectedEffects")
        let effects = PoisonedStrike.play(snapshot: makeSnapshotWithTwoEnemies(), targetEnemyIndex: 1)
        XCTAssertEqual(
            effects,
            [
                .dealDamage(source: .player, target: .enemy(index: 1), base: 5),
                .applyStatus(target: .enemy(index: 1), statusId: "poison", stacks: 2),
            ]
        )
    }

    func testPurificationRitual_play_producesExpectedEffects() {

        print("🧪 测试：testPurificationRitual_play_producesExpectedEffects")
        let effects = PurificationRitual.play(snapshot: makeSnapshot(), targetEnemyIndex: nil)
        XCTAssertEqual(
            effects,
            [
                .clearMadness(amount: 0),
                .discardRandomHand(count: 1),
            ]
        )
    }

    func testPurificationRitualPlus_play_producesExpectedEffects() {

        print("🧪 测试：testPurificationRitualPlus_play_producesExpectedEffects")
        let effects = PurificationRitualPlus.play(snapshot: makeSnapshot(), targetEnemyIndex: nil)
        XCTAssertEqual(
            effects,
            [
                .clearMadness(amount: 0),
            ]
        )
    }

    func testProphecyEcho_play_producesExpectedEffects() {

        print("🧪 测试：testProphecyEcho_play_producesExpectedEffects")
        let effects = ProphecyEcho.play(snapshot: makeSnapshot(), targetEnemyIndex: 0)
        XCTAssertEqual(
            effects,
            [
                .dealDamageBasedOnForesightCount(source: .player, target: .enemy(index: 0), basePerForesight: 3),
                .applyStatus(target: .player, statusId: Madness.id, stacks: 1),
            ]
        )
    }

    func testProphecyEchoPlus_play_producesExpectedEffects() {

        print("🧪 测试：testProphecyEchoPlus_play_producesExpectedEffects")
        let effects = ProphecyEchoPlus.play(snapshot: makeSnapshot(), targetEnemyIndex: 0)
        XCTAssertEqual(
            effects,
            [
                .dealDamageBasedOnForesightCount(source: .player, target: .enemy(index: 0), basePerForesight: 4),
                .applyStatus(target: .player, statusId: Madness.id, stacks: 1),
            ]
        )
    }

    func testSequenceResonanceCard_play_producesExpectedEffects() {

        print("🧪 测试：testSequenceResonanceCard_play_producesExpectedEffects")
        let effects = SequenceResonanceCard.play(snapshot: makeSnapshot(), targetEnemyIndex: nil)
        XCTAssertEqual(
            effects,
            [
                .applyStatus(target: .player, statusId: SequenceResonance.id, stacks: 1),
                .applyStatus(target: .player, statusId: Madness.id, stacks: 1),
            ]
        )
    }

    func testSequenceResonanceCardPlus_play_producesExpectedEffects() {

        print("🧪 测试：testSequenceResonanceCardPlus_play_producesExpectedEffects")
        let effects = SequenceResonanceCardPlus.play(snapshot: makeSnapshot(), targetEnemyIndex: nil)
        XCTAssertEqual(
            effects,
            [
                .applyStatus(target: .player, statusId: SequenceResonance.id, stacks: 2),
                .applyStatus(target: .player, statusId: Madness.id, stacks: 1),
            ]
        )
    }
}

