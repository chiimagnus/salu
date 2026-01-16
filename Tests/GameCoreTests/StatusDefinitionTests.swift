import XCTest
@testable import GameCore

/// StatusDefinition 单元测试
///
/// 目的：
/// - 验证关键状态的数值规则（易伤/虚弱/脆弱/力量/敏捷/中毒）
/// - 验证 decay/phase/priority 的设计意图（用于确定性结算）
final class StatusDefinitionTests: XCTestCase {
    /// 易伤：受到伤害 +50%。
    func testVulnerable_increasesIncomingDamageBy50Percent() {
        print("🧪 测试：testVulnerable_increasesIncomingDamageBy50Percent")
        XCTAssertEqual(Vulnerable.modifyIncomingDamage(10, stacks: 1), 15)
    }
    
    /// 虚弱：造成伤害 -25%，并向下取整。
    func testWeak_reducesOutgoingDamageBy25Percent_floor() {
        print("🧪 测试：testWeak_reducesOutgoingDamageBy25Percent_floor")
        // 9 * 0.75 = 6.75 -> 6
        XCTAssertEqual(Weak.modifyOutgoingDamage(9, stacks: 1), 6)
    }
    
    /// 脆弱：获得格挡 -25%，并向下取整。
    func testFrail_reducesBlockBy25Percent_floor() {
        print("🧪 测试：testFrail_reducesBlockBy25Percent_floor")
        // 8 * 0.75 = 6.0 -> 6
        XCTAssertEqual(Frail.modifyBlock(8, stacks: 1), 6)
    }
    
    /// 力量：输出伤害 +N；且不递减（decay == none）。
    func testStrength_addsOutgoingDamage() {
        print("🧪 测试：testStrength_addsOutgoingDamage")
        XCTAssertEqual(Strength.modifyOutgoingDamage(6, stacks: 2), 8)
        XCTAssertEqual(Strength.decay, .none)
        XCTAssertEqual(Strength.outgoingDamagePhase, .add)
    }
    
    /// 敏捷：获得格挡 +N；且不递减（decay == none）。
    func testDexterity_addsBlock() {
        print("🧪 测试：testDexterity_addsBlock")
        XCTAssertEqual(Dexterity.modifyBlock(5, stacks: 3), 8)
        XCTAssertEqual(Dexterity.decay, .none)
        XCTAssertEqual(Dexterity.blockPhase, .add)
    }
    
    /// 中毒：回合结束造成等于层数的伤害，并每回合结束递减 1 层。
    func testPoison_onTurnEnd_dealsDamageEqualToStacks_andDecaysEachTurn() {
        print("🧪 测试：testPoison_onTurnEnd_dealsDamageEqualToStacks_andDecaysEachTurn")
        let snapshot = BattleSnapshot(
            turn: 1,
            player: Entity(id: "p", name: LocalizedText("玩家", "玩家"), maxHP: 10),
            enemies: [Entity(id: "e", name: LocalizedText("敌人", "敌人"), maxHP: 10, enemyId: "jaw_worm")],
            energy: 3
        )
        
        let effects = Poison.onTurnEnd(owner: .player, stacks: 4, snapshot: snapshot)
        let expected: [BattleEffect] = [
            .dealDamage(source: .player, target: .player, base: 4)
        ]
        XCTAssertEqual(effects, expected)
        XCTAssertEqual(Poison.decay, .turnEnd(decreaseBy: 1))
    }
}

