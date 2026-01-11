// MARK: - 起始卡牌（安德的基础牌组）

// ============================================================
// Strike (凝视之触)
// ============================================================

/// 凝视之触
/// 攻击牌，造成 6 点伤害
public struct Strike: CardDefinition {
    public static let id: CardID = "strike"
    public static let name = "凝视之触"
    public static let type: CardType = .attack
    public static let rarity: CardRarity = .starter
    public static let cost = 1
    public static let rulesText = "以目光为刃。造成 6 点伤害。"
    public static let upgradedId: CardID? = "strike+"
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        let target = EffectTarget.enemy(index: targetEnemyIndex ?? 0)
        return [.dealDamage(source: .player, target: target, base: 6)]
    }
}

/// 凝视之触+
/// 攻击牌，造成 9 点伤害
public struct StrikePlus: CardDefinition {
    public static let id: CardID = "strike+"
    public static let name = "凝视之触+"
    public static let type: CardType = .attack
    public static let rarity: CardRarity = .starter
    public static let cost = 1
    public static let rulesText = "凝视深渊，深渊亦凝视着你。造成 9 点伤害。"
    public static let upgradedId: CardID? = nil
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        let target = EffectTarget.enemy(index: targetEnemyIndex ?? 0)
        return [.dealDamage(source: .player, target: target, base: 9)]
    }
}

// ============================================================
// Defend (灰雾护盾)
// ============================================================

/// 灰雾护盾
/// 技能牌，获得 5 点格挡
public struct Defend: CardDefinition {
    public static let id: CardID = "defend"
    public static let name = "灰雾护盾"
    public static let type: CardType = .skill
    public static let rarity: CardRarity = .starter
    public static let cost = 1
    public static let rulesText = "召唤迷雾庇护。获得 5 点格挡。"
    public static let upgradedId: CardID? = "defend+"
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        return [.gainBlock(target: .player, base: 5)]
    }
}

/// 灰雾护盾+
/// 技能牌，获得 8 点格挡
public struct DefendPlus: CardDefinition {
    public static let id: CardID = "defend+"
    public static let name = "灰雾护盾+"
    public static let type: CardType = .skill
    public static let rarity: CardRarity = .starter
    public static let cost = 1
    public static let rulesText = "迷雾凝聚成形。获得 8 点格挡。"
    public static let upgradedId: CardID? = nil
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        return [.gainBlock(target: .player, base: 8)]
    }
}

// ============================================================
// Bash (深渊重锤)
// ============================================================

/// 深渊重锤
/// 攻击牌，造成 8 点伤害，给予 2 层易伤
public struct Bash: CardDefinition {
    public static let id: CardID = "bash"
    public static let name = "深渊重锤"
    public static let type: CardType = .attack
    public static let rarity: CardRarity = .starter
    public static let cost = 2
    public static let rulesText = "自深渊汲取力量。造成 8 点伤害，给予 2 层易伤。"
    public static let upgradedId: CardID? = "bash+"
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        let target = EffectTarget.enemy(index: targetEnemyIndex ?? 0)
        return [
            .dealDamage(source: .player, target: target, base: 8),
            .applyStatus(target: target, statusId: "vulnerable", stacks: 2)
        ]
    }
}

/// 深渊重锤+
/// 攻击牌，造成 10 点伤害，给予 3 层易伤
public struct BashPlus: CardDefinition {
    public static let id: CardID = "bash+"
    public static let name = "深渊重锤+"
    public static let type: CardType = .attack
    public static let rarity: CardRarity = .starter
    public static let cost = 2
    public static let rulesText = "深渊的力量在你体内觉醒。造成 10 点伤害，给予 3 层易伤。"
    public static let upgradedId: CardID? = nil
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        let target = EffectTarget.enemy(index: targetEnemyIndex ?? 0)
        return [
            .dealDamage(source: .player, target: target, base: 10),
            .applyStatus(target: target, statusId: "vulnerable", stacks: 3)
        ]
    }
}

