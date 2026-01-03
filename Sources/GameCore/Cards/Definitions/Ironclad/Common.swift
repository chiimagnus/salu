/// 铁甲战士 - 普通卡牌

public enum PommelStrikeCard: CardDefinition {
    public static let id: CardID = "pommel_strike"
    public static let name = "Pommel Strike"
    public static let type: CardType = .attack
    public static let rarity: CardRarity = .common
    public static let cost = 1
    public static let rulesText = "造成 9 点伤害，抽 1 张牌"
    
    public static func play(snapshot: BattleSnapshot) -> [BattleEffect] {
        [
            .dealDamage(target: .enemy, base: 9),
            .drawCards(count: 1)
        ]
    }
}

public enum ShrugItOffCard: CardDefinition {
    public static let id: CardID = "shrug_it_off"
    public static let name = "Shrug It Off"
    public static let type: CardType = .skill
    public static let rarity: CardRarity = .common
    public static let cost = 1
    public static let rulesText = "获得 8 点格挡，抽 1 张牌"
    
    public static func play(snapshot: BattleSnapshot) -> [BattleEffect] {
        [
            .gainBlock(target: .player, amount: 8),
            .drawCards(count: 1)
        ]
    }
}

public enum InflameCard: CardDefinition {
    public static let id: CardID = "inflame"
    public static let name = "Inflame"
    public static let type: CardType = .power
    public static let rarity: CardRarity = .common
    public static let cost = 1
    public static let rulesText = "获得 2 点力量"
    
    public static func play(snapshot: BattleSnapshot) -> [BattleEffect] {
        [.applyStatus(target: .player, statusId: "strength", stacks: 2)]
    }
}

public enum ClotheslineCard: CardDefinition {
    public static let id: CardID = "clothesline"
    public static let name = "Clothesline"
    public static let type: CardType = .attack
    public static let rarity: CardRarity = .common
    public static let cost = 2
    public static let rulesText = "造成 12 点伤害，施加 2 层虚弱"
    
    public static func play(snapshot: BattleSnapshot) -> [BattleEffect] {
        [
            .dealDamage(target: .enemy, base: 12),
            .applyStatus(target: .enemy, statusId: "weak", stacks: 2)
        ]
    }
}


