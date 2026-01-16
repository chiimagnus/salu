// MARK: - Act 1 Elite Enemy Definitions

// ============================================================
// Slime Medium Acid (酸液史莱姆)
// ============================================================

/// 深渊黏体
/// 行为模式：攻击 + 涂抹（施加虚弱）
public struct SlimeMediumAcid: EnemyDefinition {
    public static let id: EnemyID = "slime_medium_acid"
    public static let name = LocalizedText("深渊黏体", "Abyssal Slime")
    public static let hpRange: ClosedRange<Int> = 28...32
    
    public static func chooseMove(selfIndex: Int, snapshot: BattleSnapshot, rng: inout SeededRNG) -> EnemyMove {
        let roll = rng.nextInt(upperBound: 100)
        
        if roll < 70 {
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️", text: LocalizedText("攻击 10", "Attack 10"), previewDamage: 10),
                effects: [.dealDamage(source: .enemy(index: selfIndex), target: .player, base: 10)]
            )
        } else {
            return EnemyMove(
                intent: EnemyIntentDisplay(
                    icon: "⚔️💀",
                    text: LocalizedText("涂抹 7 + 虚弱 1", "Lick 7 + Weak 1"),
                    previewDamage: 7
                ),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 7),
                    .applyStatus(target: .player, statusId: "weak", stacks: 1)
                ]
            )
        }
    }
}

// ============================================================
// Stone Sentinel (岩石守卫)
// ============================================================

/// 沉默守墓人（精英）
///
/// 特点：开局先叠甲，随后在高伤与多段之间切换，压迫感更强。
public struct StoneSentinel: EnemyDefinition {
    public static let id: EnemyID = "stone_sentinel"
    public static let name = LocalizedText("沉默守墓人", "Silent Gravekeeper")
    public static let hpRange: ClosedRange<Int> = 60...66
    
    public static func chooseMove(selfIndex: Int, snapshot: BattleSnapshot, rng: inout SeededRNG) -> EnemyMove {
        if snapshot.turn == 1 {
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "🛡️", text: LocalizedText("守卫姿态：格挡 18", "Guard Stance: Block 18")),
                effects: [
                    .gainBlock(target: .enemy(index: selfIndex), base: 18)
                ]
            )
        }
        
        let roll = rng.nextInt(upperBound: 100)
        if roll < 45 {
            return EnemyMove(
                intent: EnemyIntentDisplay(
                    icon: "⚔️",
                    text: LocalizedText("重击 16 + 易伤 1", "Smash 16 + Vulnerable 1"),
                    previewDamage: 16
                ),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 16),
                    .applyStatus(target: .player, statusId: "vulnerable", stacks: 1),
                ]
            )
        } else if roll < 80 {
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️⚔️", text: LocalizedText("连斩 8×2", "Double Slash 8×2"), previewDamage: 16),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 8),
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 8),
                ]
            )
        } else {
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "🛡️💪", text: LocalizedText("固守：格挡 12 + 力量 +1", "Hold Fast: Block 12 + Strength +1")),
                effects: [
                    .gainBlock(target: .enemy(index: selfIndex), base: 12),
                    .applyStatus(target: .enemy(index: selfIndex), statusId: "strength", stacks: 1),
                ]
            )
        }
    }
}
