// MARK: - Ironclad Skill Cards

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
// Shrug It Off
// ============================================================

/// Shrug It Off - 耸肩
/// 技能牌，获得 8 点格挡，抽 1 张牌
public struct ShrugItOff: CardDefinition {
    public static let id: CardID = "shrug_it_off"
    public static let name = "耸肩"
    public static let type: CardType = .skill
    public static let rarity: CardRarity = .common
    public static let cost = 1
    public static let rulesText = "获得 8 点格挡，抽 1 张牌"
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        return [
            .gainBlock(target: .player, base: 8),
            .drawCards(count: 1)
        ]
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


