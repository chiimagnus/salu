// MARK: - Ironclad Attack Cards

// ============================================================
// Strike
// ============================================================

/// Strike - 凝视之触
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

/// Strike+ - 凝视之触+
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
// Bash
// ============================================================

/// Bash - 深渊重锤
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

/// Bash+ - 深渊重锤+
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

// ============================================================
// Pommel Strike
// ============================================================

/// Pommel Strike - 触须鞭笞
/// 攻击牌，造成 9 点伤害，抽 1 张牌
public struct PommelStrike: CardDefinition {
    public static let id: CardID = "pommel_strike"
    public static let name = "触须鞭笞"
    public static let type: CardType = .attack
    public static let rarity: CardRarity = .common
    public static let cost = 1
    public static let rulesText = "灵活而致命。造成 9 点伤害，抽 1 张牌。"
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        let target = EffectTarget.enemy(index: targetEnemyIndex ?? 0)
        return [
            .dealDamage(source: .player, target: target, base: 9),
            .drawCards(count: 1)
        ]
    }
}

// ============================================================
// Clothesline
// ============================================================

/// Clothesline - 窒息缠绕
/// 攻击牌，造成 12 点伤害，给予 2 层虚弱
public struct Clothesline: CardDefinition {
    public static let id: CardID = "clothesline"
    public static let name = "窒息缠绕"
    public static let type: CardType = .attack
    public static let rarity: CardRarity = .common
    public static let cost = 2
    public static let rulesText = "来自虚空的束缚。造成 12 点伤害，给予 2 层虚弱。"
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        let target = EffectTarget.enemy(index: targetEnemyIndex ?? 0)
        return [
            .dealDamage(source: .player, target: target, base: 12),
            .applyStatus(target: target, statusId: "weak", stacks: 2)
        ]
    }
}

// ============================================================
// Cleave (横扫)
// ============================================================

/// 裂隙横断
/// 攻击牌：对所有敌人造成 4 点伤害
public struct Cleave: CardDefinition {
    public static let id: CardID = "cleave"
    public static let name = "裂隙横断"
    public static let type: CardType = .attack
    public static let rarity: CardRarity = .common
    public static let cost = 1
    public static let rulesText = "撕裂空间的一击。对所有敌人造成 4 点伤害。"
    public static let targeting: CardTargeting = .none
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        snapshot.enemies.enumerated().compactMap { index, enemy in
            guard enemy.isAlive else { return nil }
            return .dealDamage(source: .player, target: .enemy(index: index), base: 4)
        }
    }
}

// ============================================================
// Poisoned Strike (淬毒打击)
// ============================================================

/// 腐蚀之触
/// 攻击牌：造成 5 点伤害，给予 2 层中毒
public struct PoisonedStrike: CardDefinition {
    public static let id: CardID = "poisoned_strike"
    public static let name = "腐蚀之触"
    public static let type: CardType = .attack
    public static let rarity: CardRarity = .common
    public static let cost = 1
    public static let rulesText = "沾染远古毒素。造成 5 点伤害，给予 2 层中毒。"
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        let target = EffectTarget.enemy(index: targetEnemyIndex ?? 0)
        return [
            .dealDamage(source: .player, target: target, base: 5),
            .applyStatus(target: target, statusId: "poison", stacks: 2),
        ]
    }
}


