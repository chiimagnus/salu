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

// ------------------------------------------------------------
// Purification Ritual (净化仪式)
// ------------------------------------------------------------

/// 净化仪式
/// 技能牌：清除所有疯狂，弃置 1 张手牌
public struct PurificationRitual: CardDefinition {
    public static let id: CardID = "purification_ritual"
    public static let name = "净化仪式"
    public static let type: CardType = .skill
    public static let rarity: CardRarity = .uncommon
    public static let cost = 2
    public static let rulesText = "「遗忘是一种慈悲——也是一种代价。」清除所有疯狂，随机弃置 1 张手牌。"
    public static let upgradedId: CardID? = "purification_ritual+"

    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        _ = snapshot
        _ = targetEnemyIndex
        return [
            .clearMadness(amount: 0),
            .discardRandomHand(count: 1),
        ]
    }
}

/// 净化仪式+
/// 技能牌：清除所有疯狂，不弃牌
public struct PurificationRitualPlus: CardDefinition {
    public static let id: CardID = "purification_ritual+"
    public static let name = "净化仪式+"
    public static let type: CardType = .skill
    public static let rarity: CardRarity = .uncommon
    public static let cost = 2
    public static let rulesText = "「遗忘不再需要代价。」清除所有疯狂。"
    public static let upgradedId: CardID? = nil

    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        _ = snapshot
        _ = targetEnemyIndex
        return [
            .clearMadness(amount: 0),
        ]
    }
}

// ------------------------------------------------------------
// Prophecy Echo (预言回响)
// ------------------------------------------------------------

/// 预言回响
/// 攻击牌：造成 3 伤害 × 本回合预知次数，+1 疯狂
public struct ProphecyEcho: CardDefinition {
    public static let id: CardID = "prophecy_echo"
    public static let name = "预言回响"
    public static let type: CardType = .attack
    public static let rarity: CardRarity = .uncommon
    public static let cost = 1
    public static let rulesText = "「每一次窥探，都在时间线上留下裂痕。」造成 3 伤害 × 本回合预知次数。+1 疯狂。"
    public static let upgradedId: CardID? = "prophecy_echo+"

    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        let target = EffectTarget.enemy(index: targetEnemyIndex ?? 0)
        return [
            .dealDamageBasedOnForesightCount(source: .player, target: target, basePerForesight: 3),
            .applyStatus(target: .player, statusId: Madness.id, stacks: 1),
        ]
    }
}

/// 预言回响+
/// 攻击牌：造成 4 伤害 × 本回合预知次数，+1 疯狂
public struct ProphecyEchoPlus: CardDefinition {
    public static let id: CardID = "prophecy_echo+"
    public static let name = "预言回响+"
    public static let type: CardType = .attack
    public static let rarity: CardRarity = .uncommon
    public static let cost = 1
    public static let rulesText = "「裂痕回响成雷鸣。」造成 4 伤害 × 本回合预知次数。+1 疯狂。"
    public static let upgradedId: CardID? = nil

    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        let target = EffectTarget.enemy(index: targetEnemyIndex ?? 0)
        return [
            .dealDamageBasedOnForesightCount(source: .player, target: target, basePerForesight: 4),
            .applyStatus(target: .player, statusId: Madness.id, stacks: 1),
        ]
    }
}

// ============================================================
// MARK: - Rare Cards (稀有卡)
// ============================================================

// ------------------------------------------------------------
// Abyssal Gaze (深渊凝视)
// ------------------------------------------------------------

/// 深渊凝视
/// 攻击牌：对目标造成 18 点伤害
public struct AbyssalGaze: CardDefinition {
    public static let id: CardID = "abyssal_gaze"
    public static let name = "深渊凝视"
    public static let type: CardType = .attack
    public static let rarity: CardRarity = .rare
    public static let cost = 2
    public static let rulesText = "「当你凝视深渊时，深渊也在凝视你。」对目标造成 18 点伤害。"
    public static let upgradedId: CardID? = "abyssal_gaze+"
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        let target = targetEnemyIndex ?? 0
        return [
            .dealDamage(source: .player, target: .enemy(index: target), base: 18)
        ]
    }
}

/// 深渊凝视+
/// 攻击牌：对目标造成 24 点伤害
public struct AbyssalGazePlus: CardDefinition {
    public static let id: CardID = "abyssal_gaze+"
    public static let name = "深渊凝视+"
    public static let type: CardType = .attack
    public static let rarity: CardRarity = .rare
    public static let cost = 2
    public static let rulesText = "「深渊的回望更为清晰。」对目标造成 24 点伤害。"
    public static let upgradedId: CardID? = nil
    
    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        let target = targetEnemyIndex ?? 0
        return [
            .dealDamage(source: .player, target: .enemy(index: target), base: 24)
        ]
    }
}

// ------------------------------------------------------------
// Sequence Resonance (序列共鸣)
// ------------------------------------------------------------

/// 序列共鸣
/// 能力牌：本场战斗中，每次预知后获得 1 格挡，+1 疯狂
public struct SequenceResonanceCard: CardDefinition {
    public static let id: CardID = "sequence_resonance"
    public static let name = "序列共鸣"
    public static let type: CardType = .power
    public static let rarity: CardRarity = .rare
    public static let cost = 3
    public static let rulesText = "「序列之间存在共鸣——占卜师能听见它们的低语。」本场战斗中，每次预知后获得 1 格挡。+1 疯狂。"
    public static let upgradedId: CardID? = "sequence_resonance+"

    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        _ = snapshot
        _ = targetEnemyIndex
        return [
            .applyStatus(target: .player, statusId: SequenceResonance.id, stacks: 1),
            .applyStatus(target: .player, statusId: Madness.id, stacks: 1),
        ]
    }
}

/// 序列共鸣+
/// 能力牌：本场战斗中，每次预知后获得 2 格挡，+1 疯狂
public struct SequenceResonanceCardPlus: CardDefinition {
    public static let id: CardID = "sequence_resonance+"
    public static let name = "序列共鸣+"
    public static let type: CardType = .power
    public static let rarity: CardRarity = .rare
    public static let cost = 3
    public static let rulesText = "「共鸣化作屏障。」本场战斗中，每次预知后获得 2 格挡。+1 疯狂。"
    public static let upgradedId: CardID? = nil

    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        _ = snapshot
        _ = targetEnemyIndex
        return [
            .applyStatus(target: .player, statusId: SequenceResonance.id, stacks: 2),
            .applyStatus(target: .player, statusId: Madness.id, stacks: 1),
        ]
    }
}
