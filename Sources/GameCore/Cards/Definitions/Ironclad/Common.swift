// MARK: - Common Ironclad Cards

// ============================================================
// Pommel Strike
// ============================================================

/// Pommel Strike - 柄击
/// 攻击牌，造成 9 点伤害，抽 1 张牌
public struct PommelStrike: CardDefinition {
    public static let id: CardID = "pommel_strike"
    public static let name = "Pommel Strike"
    public static let type: CardType = .attack
    public static let rarity: CardRarity = .common
    public static let cost = 1
    public static let rulesText = "造成 9 点伤害，抽 1 张牌"
    
    public static func play(snapshot: BattleSnapshot) -> [BattleEffect] {
        return [
            .dealDamage(target: .enemy, base: 9),
            .drawCards(count: 1)
        ]
    }
}

// ============================================================
// Shrug It Off
// ============================================================

/// Shrug It Off - 耸肩
/// 技能牌，获得 8 点格挡，抽 1 张牌
public struct ShrugItOff: CardDefinition {
    public static let id: CardID = "shrug_it_off"
    public static let name = "Shrug It Off"
    public static let type: CardType = .skill
    public static let rarity: CardRarity = .common
    public static let cost = 1
    public static let rulesText = "获得 8 点格挡，抽 1 张牌"
    
    public static func play(snapshot: BattleSnapshot) -> [BattleEffect] {
        return [
            .gainBlock(target: .player, base: 8),
            .drawCards(count: 1)
        ]
    }
}

// ============================================================
// Inflame
// ============================================================

/// Inflame - 燃烧
/// 能力牌，获得 2 点力量
public struct Inflame: CardDefinition {
    public static let id: CardID = "inflame"
    public static let name = "Inflame"
    public static let type: CardType = .power
    public static let rarity: CardRarity = .uncommon
    public static let cost = 1
    public static let rulesText = "获得 2 点力量"
    
    public static func play(snapshot: BattleSnapshot) -> [BattleEffect] {
        return [
            .applyStatus(target: .player, statusId: "strength", stacks: 2)
        ]
    }
}

// ============================================================
// Clothesline
// ============================================================

/// Clothesline - 晾衣绳
/// 攻击牌，造成 12 点伤害，给予 2 层虚弱
public struct Clothesline: CardDefinition {
    public static let id: CardID = "clothesline"
    public static let name = "Clothesline"
    public static let type: CardType = .attack
    public static let rarity: CardRarity = .uncommon
    public static let cost = 2
    public static let rulesText = "造成 12 点伤害，给予 2 层虚弱"
    
    public static func play(snapshot: BattleSnapshot) -> [BattleEffect] {
        return [
            .dealDamage(target: .enemy, base: 12),
            .applyStatus(target: .enemy, statusId: "weak", stacks: 2)
        ]
    }
}
