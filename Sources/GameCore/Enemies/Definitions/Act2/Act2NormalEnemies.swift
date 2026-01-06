// MARK: - Act 2 Normal Enemy Definitions

// ============================================================
// Shadow Stalker (幽影刺客)
// ============================================================

/// 幽影刺客（Act2 普通敌人）
///
/// 节奏：
/// - 开局更倾向施加虚弱
/// - 后续在高伤单击与叠甲之间切换
public struct ShadowStalker: EnemyDefinition {
    public static let id: EnemyID = "shadow_stalker"
    public static let name = "幽影刺客"
    public static let hpRange: ClosedRange<Int> = 32...36
    
    public static func chooseMove(selfIndex: Int, snapshot: BattleSnapshot, rng: inout SeededRNG) -> EnemyMove {
        if snapshot.turn == 1 {
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "🌀", text: "扰乱：虚弱 2"),
                effects: [
                    .applyStatus(target: .player, statusId: "weak", stacks: 2)
                ]
            )
        }
        
        let roll = rng.nextInt(upperBound: 100)
        if roll < 55 {
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️", text: "刺杀 10", previewDamage: 10),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 10)
                ]
            )
        } else {
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "🛡️", text: "潜行：格挡 12"),
                effects: [
                    .gainBlock(target: .enemy(index: selfIndex), base: 12)
                ]
            )
        }
    }
}

// ============================================================
// Clockwork Sentinel (机械哨兵)
// ============================================================

/// 机械哨兵（Act2 普通敌人）
///
/// 特点：
/// - 多段伤害更克制低格挡
/// - 偶尔自我强化（力量+1）
public struct ClockworkSentinel: EnemyDefinition {
    public static let id: EnemyID = "clockwork_sentinel"
    public static let name = "机械哨兵"
    public static let hpRange: ClosedRange<Int> = 36...40
    
    public static func chooseMove(selfIndex: Int, snapshot: BattleSnapshot, rng: inout SeededRNG) -> EnemyMove {
        let roll = rng.nextInt(upperBound: 100)
        
        if roll < 60 {
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️⚔️", text: "连射 6×2", previewDamage: 12),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 6),
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 6),
                ]
            )
        } else if roll < 85 {
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "🛡️", text: "装甲：格挡 10"),
                effects: [
                    .gainBlock(target: .enemy(index: selfIndex), base: 10)
                ]
            )
        } else {
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "💪", text: "过载：力量 +1"),
                effects: [
                    .applyStatus(target: .enemy(index: selfIndex), statusId: "strength", stacks: 1)
                ]
            )
        }
    }
}


