import XCTest
@testable import GameCore

final class DamageAndBlockCalculatorTests: XCTestCase {
    func testDamageCalculator_appliesAddBeforeMultiply_withRounding() {
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
    
    func testBlockCalculator_appliesAddBeforeMultiply_withRounding() {
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


