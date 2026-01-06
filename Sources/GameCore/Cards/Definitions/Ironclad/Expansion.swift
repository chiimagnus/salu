// MARK: - Act 1 Expansion Cards (P7)

// ============================================================
// Cleave (横扫)
// ============================================================

/// 横扫
/// 攻击牌：对所有敌人造成 4 点伤害
public struct Cleave: CardDefinition {
    public static let id: CardID = "cleave"
    public static let name = "横扫"
    public static let type: CardType = .attack
    public static let rarity: CardRarity = .common
    public static let cost = 1
    public static let rulesText = "对所有敌人造成 4 点伤害"
    public static let targeting: CardTargeting = .none
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        snapshot.enemies.enumerated().compactMap { index, enemy in
            guard enemy.isAlive else { return nil }
            return .dealDamage(source: .player, target: .enemy(index: index), base: 4)
        }
    }
}

// ============================================================
// Intimidate (威吓)
// ============================================================

/// 威吓
/// 技能牌：使所有敌人获得 2 层虚弱
public struct Intimidate: CardDefinition {
    public static let id: CardID = "intimidate"
    public static let name = "威吓"
    public static let type: CardType = .skill
    public static let rarity: CardRarity = .common
    public static let cost = 1
    public static let rulesText = "使所有敌人获得 2 层虚弱"
    public static let targeting: CardTargeting = .none
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        snapshot.enemies.enumerated().compactMap { index, enemy in
            guard enemy.isAlive else { return nil }
            return .applyStatus(target: .enemy(index: index), statusId: "weak", stacks: 2)
        }
    }
}

// ============================================================
// Agile Stance (敏捷姿态)
// ============================================================

/// 敏捷姿态
/// 能力牌：获得 1 点敏捷
public struct AgileStance: CardDefinition {
    public static let id: CardID = "agile_stance"
    public static let name = "敏捷姿态"
    public static let type: CardType = .power
    public static let rarity: CardRarity = .common
    public static let cost = 1
    public static let rulesText = "获得 1 点敏捷"
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        [.applyStatus(target: .player, statusId: "dexterity", stacks: 1)]
    }
}

// ============================================================
// Poisoned Strike (淬毒打击)
// ============================================================

/// 淬毒打击
/// 攻击牌：造成 5 点伤害，给予 2 层中毒
public struct PoisonedStrike: CardDefinition {
    public static let id: CardID = "poisoned_strike"
    public static let name = "淬毒打击"
    public static let type: CardType = .attack
    public static let rarity: CardRarity = .common
    public static let cost = 1
    public static let rulesText = "造成 5 点伤害，给予 2 层中毒"
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        let target = EffectTarget.enemy(index: targetEnemyIndex ?? 0)
        return [
            .dealDamage(source: .player, target: target, base: 5),
            .applyStatus(target: target, statusId: "poison", stacks: 2),
        ]
    }
}


