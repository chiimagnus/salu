// MARK: - Act 3 Normal Enemy Definitions

// ============================================================
// Void Walker (虚无行者) - Act 3 Normal
// ============================================================

/// 虚无行者（Act3 普通敌人）
///
/// 特点：
/// - 来自虚无之心的生物
/// - 攻击时附带易伤效果
/// - 血量中等
public struct VoidWalker: EnemyDefinition {
    public static let id: EnemyID = "void_walker"
    public static let name = "虚无行者"
    public static let hpRange: ClosedRange<Int> = 42...48
    
    public static func chooseMove(selfIndex: Int, snapshot: BattleSnapshot, rng: inout SeededRNG) -> EnemyMove {
        let roll = rng.nextInt(upperBound: 100)
        
        if roll < 40 {
            // 40%：虚无之触 - 攻击 + 易伤
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "👁️", text: "虚无之触 10 + 易伤 1", previewDamage: 10),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 10),
                    .applyStatus(target: .player, statusId: "vulnerable", stacks: 1),
                ]
            )
        } else if roll < 70 {
            // 30%：重击
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️", text: "虚空撕裂 14", previewDamage: 14),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 14)
                ]
            )
        } else {
            // 30%：叠甲
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "🛡️", text: "相位转移 12"),
                effects: [
                    .gainBlock(target: .enemy(index: selfIndex), base: 12)
                ]
            )
        }
    }
}

// ============================================================
// Dream Parasite (梦境寄生者) - Act 3 Normal
// ============================================================

/// 梦境寄生者（Act3 普通敌人）
///
/// 特点：
/// - 寄生在梦境中的怪物
/// - 擅长施加状态效果
/// - 血量较低但很烦人
public struct DreamParasite: EnemyDefinition {
    public static let id: EnemyID = "dream_parasite"
    public static let name = "梦境寄生者"
    public static let hpRange: ClosedRange<Int> = 28...34
    
    public static func chooseMove(selfIndex: Int, snapshot: BattleSnapshot, rng: inout SeededRNG) -> EnemyMove {
        let roll = rng.nextInt(upperBound: 100)
        
        if roll < 35 {
            // 35%：梦魇侵蚀 - 虚弱 + 脆弱
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "😴", text: "梦魇侵蚀：虚弱 1 + 脆弱 1"),
                effects: [
                    .applyStatus(target: .player, statusId: "weak", stacks: 1),
                    .applyStatus(target: .player, statusId: "frail", stacks: 1),
                ]
            )
        } else if roll < 70 {
            // 35%：梦境啃噬 - 中毒
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "🦠", text: "梦境啃噬 6 + 中毒 3", previewDamage: 6),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 6),
                    .applyStatus(target: .player, statusId: "poison", stacks: 3),
                ]
            )
        } else {
            // 30%：吸取生命 - 攻击 + 自我回复
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "💜", text: "生命汲取 8", previewDamage: 8),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 8),
                    .heal(target: .enemy(index: selfIndex), amount: 4),
                ]
            )
        }
    }
}

