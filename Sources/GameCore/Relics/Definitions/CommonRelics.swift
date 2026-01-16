// MARK: - Common Relic Definitions (P7)

// ============================================================
// Vajra (金刚杵) - Common
// ============================================================

/// 远古骨锤
/// 效果：古神遗骸制成。战斗开始时获得 1 点力量
public struct VajraRelic: RelicDefinition {
    public static let id: RelicID = "vajra"
    public static let name = LocalizedText("远古骨锤", "Ancient Bone Hammer")
    public static let description = LocalizedText(
        "古神遗骸制成。战斗开始时获得 1 点力量。",
        "Forged from an elder god's remains. Gain 1 Strength at battle start."
    )
    public static let rarity: RelicRarity = .common
    public static let icon = "💎"
    
    public static func onBattleTrigger(_ trigger: BattleTrigger, snapshot: BattleSnapshot) -> [BattleEffect] {
        guard case .battleStart = trigger else { return [] }
        return [.applyStatus(target: .player, statusId: "strength", stacks: 1)]
    }
}

// ============================================================
// Lantern (灯笼) - Common
// ============================================================

/// 幽冥灯火
/// 效果：照亮彼岸之路。战斗开始时获得 1 点能量
public struct LanternRelic: RelicDefinition {
    public static let id: RelicID = "lantern"
    public static let name = LocalizedText("幽冥灯火", "Nether Lantern")
    public static let description = LocalizedText(
        "照亮彼岸之路。战斗开始时获得 1 点能量。",
        "Lights the path beyond. Gain 1 Energy at battle start."
    )
    public static let rarity: RelicRarity = .common
    public static let icon = "🏮"
    
    public static func onBattleTrigger(_ trigger: BattleTrigger, snapshot: BattleSnapshot) -> [BattleEffect] {
        guard case .battleStart = trigger else { return [] }
        return [.gainEnergy(amount: 1)]
    }
}

// ============================================================
// Iron Bracer (铁护臂) - Common
// ============================================================

/// 鳞甲残片
/// 效果：沉睡巨兽的鳞片。每次打出攻击牌，获得 2 点格挡
public struct IronBracerRelic: RelicDefinition {
    public static let id: RelicID = "iron_bracer"
    public static let name = LocalizedText("鳞甲残片", "Scale Shard")
    public static let description = LocalizedText(
        "沉睡巨兽的鳞片。每次打出攻击牌，获得 2 点格挡。",
        "A shard from a slumbering beast. Gain 2 Block whenever you play an Attack."
    )
    public static let rarity: RelicRarity = .common
    public static let icon = "🛡️"
    
    public static func onBattleTrigger(_ trigger: BattleTrigger, snapshot: BattleSnapshot) -> [BattleEffect] {
        guard case .cardPlayed(let cardId) = trigger else { return [] }
        let def = CardRegistry.require(cardId)
        guard def.type == .attack else { return [] }
        return [.gainBlock(target: .player, base: 2)]
    }
}

