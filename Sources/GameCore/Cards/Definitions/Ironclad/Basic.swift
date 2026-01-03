/// 铁甲战士 - 基础卡牌（含升级版）

public enum StrikeCard: CardDefinition {
    public static let id: CardID = "strike"
    public static let name = "Strike"
    public static let type: CardType = .attack
    public static let rarity: CardRarity = .basic
    public static let cost = 1
    public static let rulesText = "造成 6 点伤害"
    public static let upgradedId: CardID? = "strike_plus"
    
    public static func play(snapshot: BattleSnapshot) -> [BattleEffect] {
        [.dealDamage(target: .enemy, base: 6)]
    }
}

public enum StrikePlusCard: CardDefinition {
    public static let id: CardID = "strike_plus"
    public static let name = "Strike+"
    public static let type: CardType = .attack
    public static let rarity: CardRarity = .basic
    public static let cost = 1
    public static let rulesText = "造成 9 点伤害"
    
    public static func play(snapshot: BattleSnapshot) -> [BattleEffect] {
        [.dealDamage(target: .enemy, base: 9)]
    }
}

public enum DefendCard: CardDefinition {
    public static let id: CardID = "defend"
    public static let name = "Defend"
    public static let type: CardType = .skill
    public static let rarity: CardRarity = .basic
    public static let cost = 1
    public static let rulesText = "获得 5 点格挡"
    public static let upgradedId: CardID? = "defend_plus"
    
    public static func play(snapshot: BattleSnapshot) -> [BattleEffect] {
        [.gainBlock(target: .player, amount: 5)]
    }
}

public enum DefendPlusCard: CardDefinition {
    public static let id: CardID = "defend_plus"
    public static let name = "Defend+"
    public static let type: CardType = .skill
    public static let rarity: CardRarity = .basic
    public static let cost = 1
    public static let rulesText = "获得 8 点格挡"
    
    public static func play(snapshot: BattleSnapshot) -> [BattleEffect] {
        [.gainBlock(target: .player, amount: 8)]
    }
}

public enum BashCard: CardDefinition {
    public static let id: CardID = "bash"
    public static let name = "Bash"
    public static let type: CardType = .attack
    public static let rarity: CardRarity = .basic
    public static let cost = 2
    public static let rulesText = "造成 8 点伤害，施加 2 层易伤"
    public static let upgradedId: CardID? = "bash_plus"
    
    public static func play(snapshot: BattleSnapshot) -> [BattleEffect] {
        [
            .dealDamage(target: .enemy, base: 8),
            .applyStatus(target: .enemy, statusId: "vulnerable", stacks: 2)
        ]
    }
}

public enum BashPlusCard: CardDefinition {
    public static let id: CardID = "bash_plus"
    public static let name = "Bash+"
    public static let type: CardType = .attack
    public static let rarity: CardRarity = .basic
    public static let cost = 2
    public static let rulesText = "造成 10 点伤害，施加 3 层易伤"
    
    public static func play(snapshot: BattleSnapshot) -> [BattleEffect] {
        [
            .dealDamage(target: .enemy, base: 10),
            .applyStatus(target: .enemy, statusId: "vulnerable", stacks: 3)
        ]
    }
}


