// MARK: - Act 1 Normal Enemy Definitions

// ============================================================
// Jaw Worm (下颚虫)
// ============================================================

/// 咀嚼者
/// 行为模式：咬（11伤害）、嚎叫（+3力量）、猛扑（7伤害）
public struct JawWorm: EnemyDefinition {
    public static let id: EnemyID = "jaw_worm"
    public static let name = "咀嚼者"
    public static let hpRange: ClosedRange<Int> = 40...44
    
    public static func chooseMove(selfIndex: Int, snapshot: BattleSnapshot, rng: inout SeededRNG) -> EnemyMove {
        let roll = rng.nextInt(upperBound: 100)
        
        if snapshot.turn == 1 {
            // 第一回合 75% 咬
            if roll < 75 {
                return EnemyMove(
                    intent: EnemyIntentDisplay(icon: "⚔️", text: "攻击 11", previewDamage: 11),
                    effects: [.dealDamage(source: .enemy(index: selfIndex), target: .player, base: 11)]
                )
            } else {
                return EnemyMove(
                    intent: EnemyIntentDisplay(icon: "💪", text: "力量 +3"),
                    effects: [.applyStatus(target: .enemy(index: selfIndex), statusId: "strength", stacks: 3)]
                )
            }
        }
        
        // 后续回合
        if roll < 45 {
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️", text: "攻击 11", previewDamage: 11),
                effects: [.dealDamage(source: .enemy(index: selfIndex), target: .player, base: 11)]
            )
        } else if roll < 75 {
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "💪", text: "力量 +3"),
                effects: [.applyStatus(target: .enemy(index: selfIndex), statusId: "strength", stacks: 3)]
            )
        } else {
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️", text: "猛扑 7", previewDamage: 7),
                effects: [.dealDamage(source: .enemy(index: selfIndex), target: .player, base: 7)]
            )
        }
    }
}

// ============================================================
// Cultist (信徒)
// ============================================================

/// 虔信者
/// 行为模式：第一回合念咒（+3力量），后续攻击
public struct Cultist: EnemyDefinition {
    public static let id: EnemyID = "cultist"
    public static let name = "虔信者"
    public static let hpRange: ClosedRange<Int> = 48...54
    
    public static func chooseMove(selfIndex: Int, snapshot: BattleSnapshot, rng: inout SeededRNG) -> EnemyMove {
        if snapshot.turn == 1 {
            // 第一回合必定念咒
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "💪", text: "力量 +3"),
                effects: [.applyStatus(target: .enemy(index: selfIndex), statusId: "strength", stacks: 3)]
            )
        }
        // 后续回合攻击
        return EnemyMove(
            intent: EnemyIntentDisplay(icon: "⚔️", text: "攻击 6", previewDamage: 6),
            effects: [.dealDamage(source: .enemy(index: selfIndex), target: .player, base: 6)]
        )
    }
}

// ============================================================
// Louse Green (绿虱子)
// ============================================================

/// 翠鳞虫
/// 行为模式：攻击为主，偶尔卷曲（+3力量）
public struct LouseGreen: EnemyDefinition {
    public static let id: EnemyID = "louse_green"
    public static let name = "翠鳞虫"
    public static let hpRange: ClosedRange<Int> = 11...17
    
    public static func chooseMove(selfIndex: Int, snapshot: BattleSnapshot, rng: inout SeededRNG) -> EnemyMove {
        let roll = rng.nextInt(upperBound: 100)
        
        if roll < 75 {
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️", text: "攻击 6", previewDamage: 6),
                effects: [.dealDamage(source: .enemy(index: selfIndex), target: .player, base: 6)]
            )
        } else {
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "💪", text: "卷曲 +3"),
                effects: [.applyStatus(target: .enemy(index: selfIndex), statusId: "strength", stacks: 3)]
            )
        }
    }
}

// ============================================================
// Louse Red (红虱子)
// ============================================================

/// 血眼虫（与翠鳞虫行为相同，但HP略低）
/// 行为模式：攻击为主，偶尔卷曲（+3力量）
public struct LouseRed: EnemyDefinition {
    public static let id: EnemyID = "louse_red"
    public static let name = "血眼虫"
    public static let hpRange: ClosedRange<Int> = 10...15
    
    public static func chooseMove(selfIndex: Int, snapshot: BattleSnapshot, rng: inout SeededRNG) -> EnemyMove {
        let roll = rng.nextInt(upperBound: 100)
        
        if roll < 75 {
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️", text: "攻击 6", previewDamage: 6),
                effects: [.dealDamage(source: .enemy(index: selfIndex), target: .player, base: 6)]
            )
        } else {
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "💪", text: "卷曲 +3"),
                effects: [.applyStatus(target: .enemy(index: selfIndex), statusId: "strength", stacks: 3)]
            )
        }
    }
}

// ============================================================
// Spore Beast (孢子兽)
// ============================================================

/// 腐菌体（普通敌人）
///
/// 特点：带有轻度控制（脆弱/中毒），但伤害不高。
public struct SporeBeast: EnemyDefinition {
    public static let id: EnemyID = "spore_beast"
    public static let name = "腐菌体"
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
// Acid Slime Small (酸液幼体)
// ============================================================

/// 溶蚀幼崽（普通敌人）
///
/// 特点：较低生命值，攻击与"涂抹"两种动作。
public struct SlimeSmallAcid: EnemyDefinition {
    public static let id: EnemyID = "slime_small_acid"
    public static let name = "溶蚀幼崽"
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


