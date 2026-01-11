// MARK: - 普通卡牌（奖励/商店可获得）

// ============================================================
// MARK: - 攻击卡
// ============================================================

// ------------------------------------------------------------
// Pommel Strike (触须鞭笞)
// ------------------------------------------------------------

/// 触须鞭笞
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

// ------------------------------------------------------------
// Clothesline (窒息缠绕)
// ------------------------------------------------------------

/// 窒息缠绕
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

// ------------------------------------------------------------
// Cleave (裂隙横断)
// ------------------------------------------------------------

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

// ------------------------------------------------------------
// Poisoned Strike (腐蚀之触)
// ------------------------------------------------------------

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

// ============================================================
// MARK: - 技能卡
// ============================================================

// ------------------------------------------------------------
// Shrug It Off (躯壳硬化)
// ------------------------------------------------------------

/// 躯壳硬化
/// 技能牌，获得 8 点格挡，抽 1 张牌
public struct ShrugItOff: CardDefinition {
    public static let id: CardID = "shrug_it_off"
    public static let name = "躯壳硬化"
    public static let type: CardType = .skill
    public static let rarity: CardRarity = .common
    public static let cost = 1
    public static let rulesText = "身体短暂石化。获得 8 点格挡，抽 1 张牌。"
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        return [
            .gainBlock(target: .player, base: 8),
            .drawCards(count: 1)
        ]
    }
}

// ------------------------------------------------------------
// Intimidate (疯狂低语)
// ------------------------------------------------------------

/// 疯狂低语
/// 技能牌：使所有敌人获得 2 层虚弱
public struct Intimidate: CardDefinition {
    public static let id: CardID = "intimidate"
    public static let name = "疯狂低语"
    public static let type: CardType = .skill
    public static let rarity: CardRarity = .common
    public static let cost = 1
    public static let rulesText = "令敌人精神崩溃。使所有敌人获得 2 层虚弱。"
    public static let targeting: CardTargeting = .none
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        snapshot.enemies.enumerated().compactMap { index, enemy in
            guard enemy.isAlive else { return nil }
            return .applyStatus(target: .enemy(index: index), statusId: "weak", stacks: 2)
        }
    }
}

// ============================================================
// MARK: - 能力卡
// ============================================================

// ------------------------------------------------------------
// Inflame (禁忌献祭)
// ------------------------------------------------------------

/// 禁忌献祭
/// 能力牌，获得 2 点力量
public struct Inflame: CardDefinition {
    public static let id: CardID = "inflame"
    public static let name = "禁忌献祭"
    public static let type: CardType = .power
    public static let rarity: CardRarity = .common
    public static let cost = 1
    public static let rulesText = "以理智换取力量。获得 2 点力量。"
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        return [
            .applyStatus(target: .player, statusId: "strength", stacks: 2)
        ]
    }
}

// ------------------------------------------------------------
// Agile Stance (虚空步)
// ------------------------------------------------------------

/// 虚空步
/// 能力牌：获得 1 点敏捷
public struct AgileStance: CardDefinition {
    public static let id: CardID = "agile_stance"
    public static let name = "虚空步"
    public static let type: CardType = .power
    public static let rarity: CardRarity = .common
    public static let cost = 1
    public static let rulesText = "踏入另一维度。获得 1 点敏捷。"
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        [.applyStatus(target: .player, statusId: "dexterity", stacks: 1)]
    }
}

