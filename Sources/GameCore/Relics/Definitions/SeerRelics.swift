// MARK: - Seer Sequence Relic Definitions (占卜家序列遗物)

// ============================================================
// MARK: - Common Relics (普通遗物)
// ============================================================

// ------------------------------------------------------------
// Third Eye (第三只眼) - Common
// ------------------------------------------------------------

/// 第三只眼
/// 效果：战斗开始时预知 2
/// 风味：「闭上双眼，才能看见真相。」
public struct ThirdEyeRelic: RelicDefinition {
    public static let id: RelicID = "third_eye"
    public static let name = LocalizedText("第三只眼", "Third Eye")
    public static let description = LocalizedText(
        "闭上双眼，才能看见真相。战斗开始时预知 2。",
        "Close your eyes to see the truth. Foresee 2 at battle start."
    )
    public static let rarity: RelicRarity = .common
    public static let icon = "👁️"
    
    public static func onBattleTrigger(_ trigger: BattleTrigger, snapshot: BattleSnapshot) -> [BattleEffect] {
        guard case .battleStart = trigger else { return [] }
        return [.foresight(count: 2)]
    }
}

// ------------------------------------------------------------
// Broken Pocket Watch (破碎怀表) - Common
// ------------------------------------------------------------

/// 破碎怀表
/// 效果：每回合首次预知时，额外预知 1 张
/// 风味：「时间在这里断裂——又在这里重叠。」
/// 注意：此效果需要在 BattleEngine.applyForesight() 中检查并应用
public struct BrokenWatchRelic: RelicDefinition {
    public static let id: RelicID = "broken_watch"
    public static let name = LocalizedText("破碎怀表", "Shattered Pocketwatch")
    public static let description = LocalizedText(
        "时间在这里断裂——又在这里重叠。每回合首次预知时，额外预知 1 张。",
        "Time fractures here—and overlaps again. The first Foresee each turn, Foresee 1 extra."
    )
    public static let rarity: RelicRarity = .common
    public static let icon = "⏱️"
    
    public static func onBattleTrigger(_ trigger: BattleTrigger, snapshot: BattleSnapshot) -> [BattleEffect] {
        // 此遗物的效果在 BattleEngine.applyForesight() 中实现
        return []
    }
}

// ============================================================
// MARK: - Uncommon Relics (罕见遗物)
// ============================================================

// ------------------------------------------------------------
// Sanity Anchor (理智之锚) - Uncommon
// ------------------------------------------------------------

/// 理智之锚
/// 效果：所有疯狂阈值 +3（延迟负面效果触发）
/// 风味：「抓住这根锚链——它是你最后的理智。」
/// 注意：此效果需要在 BattleEngine.checkMadnessThresholds() 中检查并应用
public struct SanityAnchorRelic: RelicDefinition {
    public static let id: RelicID = "sanity_anchor"
    public static let name = LocalizedText("理智之锚", "Sanity Anchor")
    public static let description = LocalizedText(
        "抓住这根锚链——它是你最后的理智。所有疯狂阈值 +3。",
        "Hold fast to this anchor—your last shred of sanity. All Madness thresholds +3."
    )
    public static let rarity: RelicRarity = .uncommon
    public static let icon = "⚓"
    
    /// 阈值偏移量
    public static let thresholdOffset = 3
    
    public static func onBattleTrigger(_ trigger: BattleTrigger, snapshot: BattleSnapshot) -> [BattleEffect] {
        // 此遗物的效果是被动的，在 BattleEngine.checkMadnessThresholds() 中检查
        return []
    }
}

// ------------------------------------------------------------
// Abyssal Eye (深渊之瞳) - Uncommon
// ------------------------------------------------------------

/// 深渊之瞳
/// 效果：战斗开始时预知 3，+1 疯狂
/// 风味：「深渊赠予你洞察——代价是它也在注视你。」
public struct AbyssalEyeRelic: RelicDefinition {
    public static let id: RelicID = "abyssal_eye"
    public static let name = LocalizedText("深渊之瞳", "Abyssal Eye")
    public static let description = LocalizedText(
        "深渊赠予你洞察——代价是它也在注视你。战斗开始时预知 3，+1 疯狂。",
        "The abyss grants insight—at the cost of its gaze upon you. Foresee 3 and gain +1 Madness at battle start."
    )
    public static let rarity: RelicRarity = .uncommon
    public static let icon = "🔮"
    
    public static func onBattleTrigger(_ trigger: BattleTrigger, snapshot: BattleSnapshot) -> [BattleEffect] {
        guard case .battleStart = trigger else { return [] }
        return [
            .foresight(count: 3),
            .applyStatus(target: .player, statusId: Madness.id, stacks: 1)
        ]
    }
}

// ------------------------------------------------------------
// Prophet's Notes (预言者手札) - Uncommon
// ------------------------------------------------------------

/// 预言者手札
/// 效果：每场战斗首次使用"改写"时，不获得疯狂
/// 风味：「前人的智慧刻在纸上——墨迹下藏着血泪。」
/// 注意：此效果需要在 BattleEngine.applyRewriteIntent() 中检查并应用
public struct ProphetNotesRelic: RelicDefinition {
    public static let id: RelicID = "prophet_notes"
    public static let name = LocalizedText("预言者手札", "Seer's Notebook")
    public static let description = LocalizedText(
        "前人的智慧刻在纸上——墨迹下藏着血泪。每场战斗首次使用改写时，不获得疯狂。",
        "The wisdom of predecessors, inked with blood and tears. The first Rewrite each battle does not grant Madness."
    )
    public static let rarity: RelicRarity = .uncommon
    public static let icon = "📜"
    
    public static func onBattleTrigger(_ trigger: BattleTrigger, snapshot: BattleSnapshot) -> [BattleEffect] {
        // 此遗物的效果在 BattleEngine.applyRewriteIntent() 相关逻辑中实现
        return []
    }
}

// ============================================================
// MARK: - Rare Relics (稀有遗物)
// ============================================================

// ------------------------------------------------------------
// Madness Mask (疯狂面具) - Rare
// ------------------------------------------------------------

/// 疯狂面具
/// 效果：当疯狂 ≥6 时，攻击伤害 +50%
/// 风味：「戴上它，你会失去理智——也会获得力量。」
/// 注意：此效果需要在 BattleEngine 的伤害计算中检查并应用
public struct MadnessMaskRelic: RelicDefinition {
    public static let id: RelicID = "madness_mask"
    public static let name = LocalizedText("疯狂面具", "Mask of Madness")
    public static let description = LocalizedText(
        "戴上它，你会失去理智——也会获得力量。当疯狂 ≥6 时，攻击伤害 +50%。",
        "Wear it and you lose sanity—yet gain power. When Madness ≥6, Attack damage +50%."
    )
    public static let rarity: RelicRarity = .rare
    public static let icon = "🎭"
    
    /// 触发阈值
    public static let madnessThreshold = 6
    
    /// 伤害增加倍率
    public static let damageMultiplier = 1.5
    
    public static func onBattleTrigger(_ trigger: BattleTrigger, snapshot: BattleSnapshot) -> [BattleEffect] {
        // 此遗物的效果在 BattleEngine.applyDamage() 相关逻辑中实现
        return []
    }
}
