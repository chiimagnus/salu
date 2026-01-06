// MARK: - Act 2 Elite Enemy Definitions

// ============================================================
// Rune Guardian (符文守卫)
// ============================================================

/// 符文守卫（Act2 精英）
///
/// 特点：
/// - 开局制造易伤，放大后续伤害压力
/// - 轮换：重击 / 叠甲 / 多段
public struct RuneGuardian: EnemyDefinition {
    public static let id: EnemyID = "rune_guardian"
    public static let name = "符文守卫"
    public static let hpRange: ClosedRange<Int> = 70...76
    
    public static func chooseMove(selfIndex: Int, snapshot: BattleSnapshot, rng: inout SeededRNG) -> EnemyMove {
        if snapshot.turn == 1 {
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "💥", text: "破甲：易伤 2"),
                effects: [
                    .applyStatus(target: .player, statusId: "vulnerable", stacks: 2)
                ]
            )
        }
        
        let cycle = (snapshot.turn - 2) % 3
        switch cycle {
        case 0:
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️", text: "符文重击 18", previewDamage: 18),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 18)
                ]
            )
        case 1:
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "🛡️", text: "符文护盾：格挡 20"),
                effects: [
                    .gainBlock(target: .enemy(index: selfIndex), base: 20)
                ]
            )
        default:
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️⚔️", text: "符文连斩 9×2", previewDamage: 18),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 9),
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 9),
                ]
            )
        }
    }
}


