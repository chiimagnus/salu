// MARK: - Common Relic Definitions (P7)

// ============================================================
// Vajra (金刚杵) - Common
// ============================================================

/// 金刚杵
/// 效果：战斗开始时获得 1 点力量
public struct VajraRelic: RelicDefinition {
    public static let id: RelicID = "vajra"
    public static let name = "金刚杵"
    public static let description = "战斗开始时获得 1 点力量"
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

/// 灯笼
/// 效果：战斗开始时获得 1 点能量
public struct LanternRelic: RelicDefinition {
    public static let id: RelicID = "lantern"
    public static let name = "灯笼"
    public static let description = "战斗开始时获得 1 点能量"
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

/// 铁护臂
/// 效果：每次打出攻击牌，获得 2 点格挡
public struct IronBracerRelic: RelicDefinition {
    public static let id: RelicID = "iron_bracer"
    public static let name = "铁护臂"
    public static let description = "每次打出攻击牌，获得 2 点格挡"
    public static let rarity: RelicRarity = .common
    public static let icon = "🛡️"
    
    public static func onBattleTrigger(_ trigger: BattleTrigger, snapshot: BattleSnapshot) -> [BattleEffect] {
        guard case .cardPlayed(let cardId) = trigger else { return [] }
        let def = CardRegistry.require(cardId)
        guard def.type == .attack else { return [] }
        return [.gainBlock(target: .player, base: 2)]
    }
}


