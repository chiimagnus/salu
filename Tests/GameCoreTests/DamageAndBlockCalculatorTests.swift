import XCTest
@testable import GameCore

/// 伤害/格挡计算器单元测试
///
/// 目的：
/// - 验证状态修正顺序的**确定性**：必须先 add（力量/敏捷），再 multiply（虚弱/易伤/脆弱）
/// - 验证“向下取整”存在时顺序会影响结果，因此必须固定顺序（phase + priority）
final class DamageAndBlockCalculatorTests: XCTestCase {
    /// 验证 DamageCalculator 的顺序为：Strength(+N) → Weak(*0.75)。
    /// 如果顺序反了（先乘再加），结果会不同，从而说明确定性被破坏。
    func testDamageCalculator_appliesAddBeforeMultiply_withRounding() {
        print("🧪 测试：testDamageCalculator_appliesAddBeforeMultiply_withRounding")
        // base 3
        // Strength(+2) then Weak(*0.75) => (3+2)=5 -> 3
        // Weak then Strength would be 4（不同），用于验证顺序确定性
        var attacker = Entity(id: "a", name: "攻击者", maxHP: 10)
        attacker.statuses.apply("strength", stacks: 2)
        attacker.statuses.apply("weak", stacks: 1)
        
        let defender = Entity(id: "d", name: "防御者", maxHP: 10, enemyId: "jaw_worm")
        let result = DamageCalculator.calculate(baseDamage: 3, attacker: attacker, defender: defender)
        
        XCTAssertEqual(result, 3)
    }
    
    /// 验证 BlockCalculator 的顺序为：Dexterity(+N) → Frail(*0.75)。
    func testBlockCalculator_appliesAddBeforeMultiply_withRounding() {
        print("🧪 测试：testBlockCalculator_appliesAddBeforeMultiply_withRounding")
        // base 3
        // Dexterity(+2) then Frail(*0.75) => (3+2)=5 -> 3
        // Frail then Dexterity would be 4（不同）
        var entity = Entity(id: "p", name: "玩家", maxHP: 10)
        entity.statuses.apply("dexterity", stacks: 2)
        entity.statuses.apply("frail", stacks: 1)
        
        let result = BlockCalculator.calculate(baseBlock: 3, entity: entity)
        XCTAssertEqual(result, 3)
    }
}


