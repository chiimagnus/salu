// MARK: - Act 3 Elite Enemy Definitions

// ============================================================
// Cycle Guardian (循环守卫) - Act 3 Elite
// ============================================================

/// 循环守卫（Act3 精英）
///
/// 设计目标：
/// - 守护序列始祖的存在
/// - 高血量高伤害
/// - 有明确的攻防循环
public struct CycleGuardian: EnemyDefinition {
    public static let id: EnemyID = "cycle_guardian"
    public static let name = "循环守卫"
    public static let hpRange: ClosedRange<Int> = 85...95
    
    public static func chooseMove(selfIndex: Int, snapshot: BattleSnapshot, rng: inout SeededRNG) -> EnemyMove {
        let cycle = (snapshot.turn - 1) % 3
        
        switch cycle {
        case 0:
            // 回合 1：强化自身
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "💪", text: "循环强化：力量 +2"),
                effects: [
                    .applyStatus(target: .enemy(index: selfIndex), statusId: "strength", stacks: 2)
                ]
            )
            
        case 1:
            // 回合 2：重击
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️", text: "轮回斩击 22", previewDamage: 22),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 22)
                ]
            )
            
        default:
            // 回合 3：防御 + 攻击
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "🛡️⚔️", text: "守护反击：格挡 15 + 攻击 10", previewDamage: 10),
                effects: [
                    .gainBlock(target: .enemy(index: selfIndex), base: 15),
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 10),
                ]
            )
        }
    }
}

