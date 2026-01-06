// MARK: - Act 1 Additional Enemy Definitions (P7)

// ============================================================
// Spore Beast (孢子兽) - Normal
// ============================================================

/// 孢子兽（普通敌人）
///
/// 特点：带有轻度控制（脆弱/中毒），但伤害不高。
public struct SporeBeast: EnemyDefinition {
    public static let id: EnemyID = "spore_beast"
    public static let name = "孢子兽"
    public static let hpRange: ClosedRange<Int> = 24...28
    
    public static func chooseMove(selfIndex: Int, snapshot: BattleSnapshot, rng: inout SeededRNG) -> EnemyMove {
        // 第一回合固定喷射，保证节奏可读
        if snapshot.turn == 1 {
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "☁️", text: "孢子喷射 5 + 脆弱 1", previewDamage: 5),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 5),
                    .applyStatus(target: .player, statusId: "frail", stacks: 1),
                ]
            )
        }
        
        let roll = rng.nextInt(upperBound: 100)
        if roll < 65 {
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "☁️", text: "孢子喷射 5 + 脆弱 1", previewDamage: 5),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 5),
                    .applyStatus(target: .player, statusId: "frail", stacks: 1),
                ]
            )
        } else {
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "🛡️", text: "孢子护甲：格挡 10"),
                effects: [
                    .gainBlock(target: .enemy(index: selfIndex), base: 10)
                ]
            )
        }
    }
}

// ============================================================
// Acid Slime Small (酸液幼体) - Normal
// ============================================================

/// 酸液幼体（普通敌人）
///
/// 特点：较低生命值，攻击与“涂抹”两种动作。
public struct SlimeSmallAcid: EnemyDefinition {
    public static let id: EnemyID = "slime_small_acid"
    public static let name = "酸液幼体"
    public static let hpRange: ClosedRange<Int> = 20...24
    
    public static func chooseMove(selfIndex: Int, snapshot: BattleSnapshot, rng: inout SeededRNG) -> EnemyMove {
        let roll = rng.nextInt(upperBound: 100)
        
        if roll < 70 {
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️", text: "攻击 7", previewDamage: 7),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 7)
                ]
            )
        } else {
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️💀", text: "涂抹 4 + 虚弱 1", previewDamage: 4),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 4),
                    .applyStatus(target: .player, statusId: "weak", stacks: 1),
                ]
            )
        }
    }
}

// ============================================================
// Stone Sentinel (岩石守卫) - Elite
// ============================================================

/// 岩石守卫（精英）
///
/// 特点：开局先叠甲，随后在高伤与多段之间切换，压迫感更强。
public struct StoneSentinel: EnemyDefinition {
    public static let id: EnemyID = "stone_sentinel"
    public static let name = "岩石守卫"
    public static let hpRange: ClosedRange<Int> = 60...66
    
    public static func chooseMove(selfIndex: Int, snapshot: BattleSnapshot, rng: inout SeededRNG) -> EnemyMove {
        if snapshot.turn == 1 {
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "🛡️", text: "守卫姿态：格挡 18"),
                effects: [
                    .gainBlock(target: .enemy(index: selfIndex), base: 18)
                ]
            )
        }
        
        let roll = rng.nextInt(upperBound: 100)
        if roll < 45 {
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️", text: "重击 16 + 易伤 1", previewDamage: 16),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 16),
                    .applyStatus(target: .player, statusId: "vulnerable", stacks: 1),
                ]
            )
        } else if roll < 80 {
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️⚔️", text: "连斩 8×2", previewDamage: 16),
                effects: [
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 8),
                    .dealDamage(source: .enemy(index: selfIndex), target: .player, base: 8),
                ]
            )
        } else {
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "🛡️💪", text: "固守：格挡 12 + 力量 +1"),
                effects: [
                    .gainBlock(target: .enemy(index: selfIndex), base: 12),
                    .applyStatus(target: .enemy(index: selfIndex), statusId: "strength", stacks: 1),
                ]
            )
        }
    }
}


