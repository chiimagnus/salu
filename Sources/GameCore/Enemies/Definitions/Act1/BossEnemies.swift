// MARK: - Act 1 Boss Definitions

// ============================================================
// Toxic Colossus (毒雾巨像) - Act 1 Boss
// ============================================================

/// 毒雾巨像（Act 1 Boss）
///
/// 设计目标：
/// - 具备可理解的固定循环（4 回合一轮）
/// - 通过中毒/虚弱/脆弱制造节奏压力
/// - 每轮开始会获得力量，形成渐进压迫感
public struct ToxicColossus: EnemyDefinition {
    public static let id: EnemyID = "toxic_colossus"
    public static let name = "毒雾巨像"
    public static let hpRange: ClosedRange<Int> = 95...105
    
    public static func chooseMove(selfIndex: Int, snapshot: BattleSnapshot, rng: inout SeededRNG) -> EnemyMove {
        // 4 回合循环：1) 毒雾蓄势  2) 践踏  3) 腐蚀打击  4) 连击
        let cycle = (snapshot.turn - 1) % 4
        
        switch cycle {
        case 0:
            // 毒雾蓄势：格挡 + 中毒 + 每轮力量增长
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "☠️", text: "毒雾：中毒 3 + 格挡 8 + 力量 +1"),
                effects: [
                    .applyStatus(target: .enemy(index: selfIndex), statusId: "strength", stacks: 1),
                    .gainBlock(target: .enemy(index: selfIndex), base: 8),
                    .applyStatus(target: .player, statusId: "poison", stacks: 3),
                ]
            )
            
        case 1:
            // 践踏：高额单体伤害
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️", text: "践踏 14", previewDamage: 14),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 14)
                ]
            )
            
        case 2:
            // 腐蚀打击：伤害 + 虚弱，降低反击能力
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️🌀", text: "腐蚀打击 8 + 虚弱 2", previewDamage: 8),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 8),
                    .applyStatus(target: .player, statusId: "weak", stacks: 2),
                ]
            )
            
        default:
            // 连击：多段伤害 + 脆弱，放大后续伤害压力
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️⚔️", text: "连击 6×2 + 脆弱 1", previewDamage: 12),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 6),
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 6),
                    .applyStatus(target: .player, statusId: "frail", stacks: 1),
                ]
            )
        }
    }
}


