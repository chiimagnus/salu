// MARK: - Seer Sequence Cards (占卜家序列卡牌)

// ============================================================
// MARK: - Common Cards (普通卡)
// ============================================================

// ------------------------------------------------------------
// Spirit Sight (灵视)
// ------------------------------------------------------------

/// 灵视
/// 技能牌：预知 2，+1 疯狂
public struct SpiritSight: CardDefinition {
    public static let id: CardID = "spirit_sight"
    public static let name = "灵视"
    public static let type: CardType = .skill
    public static let rarity: CardRarity = .common
    public static let cost = 0
    public static let rulesText = "「闭上双眼，第三只眼便会睁开。」预知 2。+1 疯狂。"
    public static let upgradedId: CardID? = "spirit_sight+"
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        return [
            .foresight(count: 2),
            .applyStatus(target: .player, statusId: Madness.id, stacks: 1)
        ]
    }
}

/// 灵视+
/// 技能牌：预知 3，+1 疯狂
public struct SpiritSightPlus: CardDefinition {
    public static let id: CardID = "spirit_sight+"
    public static let name = "灵视+"
    public static let type: CardType = .skill
    public static let rarity: CardRarity = .common
    public static let cost = 0
    public static let rulesText = "「第三只眼洞察一切。」预知 3。+1 疯狂。"
    public static let upgradedId: CardID? = nil
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        return [
            .foresight(count: 3),
            .applyStatus(target: .player, statusId: Madness.id, stacks: 1)
        ]
    }
}

// ------------------------------------------------------------
// Truth Whisper (真相低语)
// ------------------------------------------------------------

/// 真相低语
/// 攻击牌：造成 5 伤害，预知 1，+1 疯狂
public struct TruthWhisper: CardDefinition {
    public static let id: CardID = "truth_whisper"
    public static let name = "真相低语"
    public static let type: CardType = .attack
    public static let rarity: CardRarity = .common
    public static let cost = 1
    public static let rulesText = "「真相是最锋利的刀刃。」造成 5 点伤害，预知 1。+1 疯狂。"
    public static let upgradedId: CardID? = "truth_whisper+"
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        let target = EffectTarget.enemy(index: targetEnemyIndex ?? 0)
        return [
            .dealDamage(source: .player, target: target, base: 5),
            .foresight(count: 1),
            .applyStatus(target: .player, statusId: Madness.id, stacks: 1)
        ]
    }
}

/// 真相低语+
/// 攻击牌：造成 7 伤害，预知 2，+1 疯狂
public struct TruthWhisperPlus: CardDefinition {
    public static let id: CardID = "truth_whisper+"
    public static let name = "真相低语+"
    public static let type: CardType = .attack
    public static let rarity: CardRarity = .common
    public static let cost = 1
    public static let rulesText = "「真相刺穿一切伪装。」造成 7 点伤害，预知 2。+1 疯狂。"
    public static let upgradedId: CardID? = nil
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        let target = EffectTarget.enemy(index: targetEnemyIndex ?? 0)
        return [
            .dealDamage(source: .player, target: target, base: 7),
            .foresight(count: 2),
            .applyStatus(target: .player, statusId: Madness.id, stacks: 1)
        ]
    }
}

// ------------------------------------------------------------
// Meditation (冥想)
// ------------------------------------------------------------

/// 冥想
/// 技能牌：获得 4 格挡，清除 2 疯狂
public struct Meditation: CardDefinition {
    public static let id: CardID = "meditation"
    public static let name = "冥想"
    public static let type: CardType = .skill
    public static let rarity: CardRarity = .common
    public static let cost = 1
    public static let rulesText = "「在疯狂的世界里，片刻宁静弥足珍贵。」获得 4 点格挡，清除 2 疯狂。"
    public static let upgradedId: CardID? = "meditation+"
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        return [
            .gainBlock(target: .player, base: 4),
            .clearMadness(amount: 2)
        ]
    }
}

/// 冥想+
/// 技能牌：获得 6 格挡，清除 3 疯狂
public struct MeditationPlus: CardDefinition {
    public static let id: CardID = "meditation+"
    public static let name = "冥想+"
    public static let type: CardType = .skill
    public static let rarity: CardRarity = .common
    public static let cost = 1
    public static let rulesText = "「深度冥想带来深度宁静。」获得 6 点格挡，清除 3 疯狂。"
    public static let upgradedId: CardID? = nil
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        return [
            .gainBlock(target: .player, base: 6),
            .clearMadness(amount: 3)
        ]
    }
}

// ------------------------------------------------------------
// Sanity Burn (理智燃烧)
// ------------------------------------------------------------

/// 理智燃烧
/// 技能牌：获得 2 力量，+3 疯狂
public struct SanityBurn: CardDefinition {
    public static let id: CardID = "sanity_burn"
    public static let name = "理智燃烧"
    public static let type: CardType = .skill
    public static let rarity: CardRarity = .common
    public static let cost = 1
    public static let rulesText = "「燃烧理智，换取力量——这是每个占卜师都会面临的诱惑。」获得 2 点力量。+3 疯狂。"
    public static let upgradedId: CardID? = "sanity_burn+"
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        return [
            .applyStatus(target: .player, statusId: Strength.id, stacks: 2),
            .applyStatus(target: .player, statusId: Madness.id, stacks: 3)
        ]
    }
}

/// 理智燃烧+
/// 技能牌：获得 3 力量，+3 疯狂
public struct SanityBurnPlus: CardDefinition {
    public static let id: CardID = "sanity_burn+"
    public static let name = "理智燃烧+"
    public static let type: CardType = .skill
    public static let rarity: CardRarity = .common
    public static let cost = 1
    public static let rulesText = "「理智的火焰燃烧得更加猛烈。」获得 3 点力量。+3 疯狂。"
    public static let upgradedId: CardID? = nil
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        return [
            .applyStatus(target: .player, statusId: Strength.id, stacks: 3),
            .applyStatus(target: .player, statusId: Madness.id, stacks: 3)
        ]
    }
}

// ============================================================
// MARK: - Uncommon Cards (罕见卡)
// ============================================================

// ------------------------------------------------------------
// Fate Rewrite (命运改写)
// ------------------------------------------------------------

/// 命运改写
/// 技能牌：改写目标敌人意图变为"防御"，+2 疯狂
public struct FateRewrite: CardDefinition {
    public static let id: CardID = "fate_rewrite"
    public static let name = "命运改写"
    public static let type: CardType = .skill
    public static let rarity: CardRarity = .uncommon
    public static let cost = 1
    public static let targeting: CardTargeting = .singleEnemy
    public static let rulesText = "「命运的丝线在我指尖缠绕——我可以剪断，也可以重编。」改写：目标敌人意图变为「防御」。+2 疯狂。"
    public static let upgradedId: CardID? = "fate_rewrite+"
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        let target = targetEnemyIndex ?? 0
        return [
            .rewriteIntent(enemyIndex: target, newIntent: .defend(block: 10)),
            .applyStatus(target: .player, statusId: Madness.id, stacks: 2)
        ]
    }
}

/// 命运改写+
/// 技能牌：改写所有敌人意图变为"防御"，+2 疯狂
public struct FateRewritePlus: CardDefinition {
    public static let id: CardID = "fate_rewrite+"
    public static let name = "命运改写+"
    public static let type: CardType = .skill
    public static let rarity: CardRarity = .uncommon
    public static let cost = 1
    public static let rulesText = "「命运在我手中重塑。」改写：所有敌人意图变为「防御」。+2 疯狂。"
    public static let upgradedId: CardID? = nil
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        // 改写所有存活敌人的意图
        var effects: [BattleEffect] = []
        for (index, enemy) in snapshot.enemies.enumerated() {
            if enemy.isAlive {
                effects.append(.rewriteIntent(enemyIndex: index, newIntent: .defend(block: 10)))
            }
        }
        effects.append(.applyStatus(target: .player, statusId: Madness.id, stacks: 2))
        return effects
    }
}

// ------------------------------------------------------------
// Time Shard (时间碎片)
// ------------------------------------------------------------

/// 时间碎片
/// 技能牌：回溯 1，抽 1 张牌，+1 疯狂
public struct TimeShard: CardDefinition {
    public static let id: CardID = "time_shard"
    public static let name = "时间碎片"
    public static let type: CardType = .skill
    public static let rarity: CardRarity = .uncommon
    public static let cost = 1
    public static let rulesText = "「过去并未消逝，只是被遗忘。」回溯 1，抽 1 张牌。+1 疯狂。"
    public static let upgradedId: CardID? = "time_shard+"
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        return [
            .rewind(count: 1),
            .drawCards(count: 1),
            .applyStatus(target: .player, statusId: Madness.id, stacks: 1)
        ]
    }
}

/// 时间碎片+
/// 技能牌：回溯 2，抽 1 张牌，+1 疯狂
public struct TimeShardPlus: CardDefinition {
    public static let id: CardID = "time_shard+"
    public static let name = "时间碎片+"
    public static let type: CardType = .skill
    public static let rarity: CardRarity = .uncommon
    public static let cost = 1
    public static let rulesText = "「时间的碎片在指尖重组。」回溯 2，抽 1 张牌。+1 疯狂。"
    public static let upgradedId: CardID? = nil
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        return [
            .rewind(count: 2),
            .drawCards(count: 1),
            .applyStatus(target: .player, statusId: Madness.id, stacks: 1)
        ]
    }
}

