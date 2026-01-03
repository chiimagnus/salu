// MARK: - Act 1 Enemy Definitions

// ============================================================
// Jaw Worm (下颚虫)
// ============================================================

/// 下颚虫
/// 行为模式：咬（11伤害）、嚎叫（+3力量）、猛扑（7伤害）
public struct JawWorm: EnemyDefinition {
    public static let id: EnemyID = "jaw_worm"
    public static let name = "下颚虫"
    public static let hpRange: ClosedRange<Int> = 40...44
    
    public static func chooseMove(snapshot: BattleSnapshot, rng: inout SeededRNG) -> EnemyMove {
        let roll = rng.nextInt(upperBound: 100)
        
        if snapshot.turn == 1 {
            // 第一回合 75% 咬
            if roll < 75 {
                return EnemyMove(
                    intent: EnemyIntentDisplay(icon: "⚔️", text: "攻击 11", previewDamage: 11),
                    effects: [.dealDamage(target: .player, base: 11)]
                )
            } else {
                return EnemyMove(
                    intent: EnemyIntentDisplay(icon: "💪", text: "力量 +3"),
                    effects: [.applyStatus(target: .enemy, statusId: "strength", stacks: 3)]
                )
            }
        }
        
        // 后续回合
        if roll < 45 {
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️", text: "攻击 11", previewDamage: 11),
                effects: [.dealDamage(target: .player, base: 11)]
            )
        } else if roll < 75 {
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "💪", text: "力量 +3"),
                effects: [.applyStatus(target: .enemy, statusId: "strength", stacks: 3)]
            )
        } else {
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️", text: "猛扑 7", previewDamage: 7),
                effects: [.dealDamage(target: .player, base: 7)]
            )
        }
    }
}

// ============================================================
// Cultist (信徒)
// ============================================================

/// 信徒
/// 行为模式：第一回合念咒（+3力量），后续攻击
public struct Cultist: EnemyDefinition {
    public static let id: EnemyID = "cultist"
    public static let name = "信徒"
    public static let hpRange: ClosedRange<Int> = 48...54
    
    public static func chooseMove(snapshot: BattleSnapshot, rng: inout SeededRNG) -> EnemyMove {
        if snapshot.turn == 1 {
            // 第一回合必定念咒
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "💪", text: "仪式 +3"),
                effects: [.applyStatus(target: .enemy, statusId: "strength", stacks: 3)]
            )
        }
        // 后续回合攻击
        return EnemyMove(
            intent: EnemyIntentDisplay(icon: "⚔️", text: "攻击 6", previewDamage: 6),
            effects: [.dealDamage(target: .player, base: 6)]
        )
    }
}

// ============================================================
// Louse Green (绿虱子)
// ============================================================

/// 绿虱子
/// 行为模式：攻击为主，偶尔卷曲（+3力量）
public struct LouseGreen: EnemyDefinition {
    public static let id: EnemyID = "louse_green"
    public static let name = "绿虱子"
    public static let hpRange: ClosedRange<Int> = 11...17
    
    public static func chooseMove(snapshot: BattleSnapshot, rng: inout SeededRNG) -> EnemyMove {
        let roll = rng.nextInt(upperBound: 100)
        
        if roll < 75 {
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️", text: "攻击 6", previewDamage: 6),
                effects: [.dealDamage(target: .player, base: 6)]
            )
        } else {
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "💪", text: "卷曲 +3"),
                effects: [.applyStatus(target: .enemy, statusId: "strength", stacks: 3)]
            )
        }
    }
}

// ============================================================
// Louse Red (红虱子)
// ============================================================

/// 红虱子（与绿虱子行为相同，但HP略低）
/// 行为模式：攻击为主，偶尔卷曲（+3力量）
public struct LouseRed: EnemyDefinition {
    public static let id: EnemyID = "louse_red"
    public static let name = "红虱子"
    public static let hpRange: ClosedRange<Int> = 10...15
    
    public static func chooseMove(snapshot: BattleSnapshot, rng: inout SeededRNG) -> EnemyMove {
        let roll = rng.nextInt(upperBound: 100)
        
        if roll < 75 {
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️", text: "攻击 6", previewDamage: 6),
                effects: [.dealDamage(target: .player, base: 6)]
            )
        } else {
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "💪", text: "卷曲 +3"),
                effects: [.applyStatus(target: .enemy, statusId: "strength", stacks: 3)]
            )
        }
    }
}

// ============================================================
// Slime Medium Acid (酸液史莱姆)
// ============================================================

/// 酸液史莱姆
/// 行为模式：攻击 + 涂抹（施加虚弱）
public struct SlimeMediumAcid: EnemyDefinition {
    public static let id: EnemyID = "slime_medium_acid"
    public static let name = "酸液史莱姆"
    public static let hpRange: ClosedRange<Int> = 28...32
    
    public static func chooseMove(snapshot: BattleSnapshot, rng: inout SeededRNG) -> EnemyMove {
        let roll = rng.nextInt(upperBound: 100)
        
        if roll < 70 {
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️", text: "攻击 10", previewDamage: 10),
                effects: [.dealDamage(target: .player, base: 10)]
            )
        } else {
            return EnemyMove(
                intent: EnemyIntentDisplay(icon: "⚔️💀", text: "涂抹 7 + 虚弱 1", previewDamage: 7),
                effects: [
                    .dealDamage(target: .player, base: 7),
                    .applyStatus(target: .player, statusId: "weak", stacks: 1)
                ]
            )
        }
    }
}
