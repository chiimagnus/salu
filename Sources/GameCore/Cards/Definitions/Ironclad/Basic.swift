// MARK: - Basic Ironclad Cards

// ============================================================
// Strike
// ============================================================

/// Strike - 打击
/// 攻击牌，造成 6 点伤害
public struct Strike: CardDefinition {
    public static let id: CardID = "strike"
    public static let name = "打击"
    public static let type: CardType = .attack
    public static let rarity: CardRarity = .starter
    public static let cost = 1
    public static let rulesText = "造成 6 点伤害"
    public static let upgradedId: CardID? = "strike+"
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        let target = EffectTarget.enemy(index: targetEnemyIndex ?? 0)
        return [.dealDamage(source: .player, target: target, base: 6)]
    }
}

/// Strike+ - 打击+
/// 攻击牌，造成 9 点伤害
public struct StrikePlus: CardDefinition {
    public static let id: CardID = "strike+"
    public static let name = "打击+"
    public static let type: CardType = .attack
    public static let rarity: CardRarity = .starter
    public static let cost = 1
    public static let rulesText = "造成 9 点伤害"
    public static let upgradedId: CardID? = nil
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        let target = EffectTarget.enemy(index: targetEnemyIndex ?? 0)
        return [.dealDamage(source: .player, target: target, base: 9)]
    }
}

// ============================================================
// Defend
// ============================================================

/// Defend - 防御
/// 技能牌，获得 5 点格挡
public struct Defend: CardDefinition {
    public static let id: CardID = "defend"
    public static let name = "防御"
    public static let type: CardType = .skill
    public static let rarity: CardRarity = .starter
    public static let cost = 1
    public static let rulesText = "获得 5 点格挡"
    public static let upgradedId: CardID? = "defend+"
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        return [.gainBlock(target: .player, base: 5)]
    }
}

/// Defend+ - 防御+
/// 技能牌，获得 8 点格挡
public struct DefendPlus: CardDefinition {
    public static let id: CardID = "defend+"
    public static let name = "防御+"
    public static let type: CardType = .skill
    public static let rarity: CardRarity = .starter
    public static let cost = 1
    public static let rulesText = "获得 8 点格挡"
    public static let upgradedId: CardID? = nil
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        return [.gainBlock(target: .player, base: 8)]
    }
}

// ============================================================
// Bash
// ============================================================

/// Bash - 重击
/// 攻击牌，造成 8 点伤害，给予 2 层易伤
public struct Bash: CardDefinition {
    public static let id: CardID = "bash"
    public static let name = "重击"
    public static let type: CardType = .attack
    public static let rarity: CardRarity = .starter
    public static let cost = 2
    public static let rulesText = "造成 8 点伤害，给予 2 层易伤"
    public static let upgradedId: CardID? = "bash+"
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        let target = EffectTarget.enemy(index: targetEnemyIndex ?? 0)
        return [
            .dealDamage(source: .player, target: target, base: 8),
            .applyStatus(target: target, statusId: "vulnerable", stacks: 2)
        ]
    }
}

/// Bash+ - 重击+
/// 攻击牌，造成 10 点伤害，给予 3 层易伤
public struct BashPlus: CardDefinition {
    public static let id: CardID = "bash+"
    public static let name = "重击+"
    public static let type: CardType = .attack
    public static let rarity: CardRarity = .starter
    public static let cost = 2
    public static let rulesText = "造成 10 点伤害，给予 3 层易伤"
    public static let upgradedId: CardID? = nil
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        let target = EffectTarget.enemy(index: targetEnemyIndex ?? 0)
        return [
            .dealDamage(source: .player, target: target, base: 10),
            .applyStatus(target: target, statusId: "vulnerable", stacks: 3)
        ]
    }
}
