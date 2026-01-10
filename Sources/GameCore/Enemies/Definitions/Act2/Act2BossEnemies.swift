// MARK: - Act 2 Boss Definitions

// ============================================================
// Chrono Watcher (时空观测者) - Act 2 Boss
// ============================================================

/// 窥视者（Act2 Boss）
///
/// 设计目标：
/// - 明确的 3 回合循环，读招成本低
/// - 通过中毒/脆弱拉长战斗风险
/// - 每轮提升力量，形成递增压迫
public struct ChronoWatcher: EnemyDefinition {
    public static let id: EnemyID = "chrono_watcher"
    public static let name = "窥视者"
    public static let hpRange: ClosedRange<Int> = 110...120
    
    public static func chooseMove(selfIndex: Int, snapshot: BattleSnapshot, rng: inout SeededRNG) -> EnemyMove {
        let cycle = (snapshot.turn - 1) % 3
        
        switch cycle {
        case 0:
            // 标记：中毒 + 脆弱 + 力量成长
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⏳", text: "时序标记：中毒 2 + 脆弱 1 + 力量 +1"),
                effects: [
                    .applyStatus(target: .enemy(index: selfIndex), statusId: "strength", stacks: 1),
                    .applyStatus(target: .player, statusId: "poison", stacks: 2),
                    .applyStatus(target: .player, statusId: "frail", stacks: 1),
                ]
            )
            
        case 1:
            // 重击
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️", text: "时间崩解 20", previewDamage: 20),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 20)
                ]
            )
            
        default:
            // 多段
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️⚔️", text: "回溯连击 8×2", previewDamage: 16),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 8),
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 8),
                ]
            )
        }
    }
}


