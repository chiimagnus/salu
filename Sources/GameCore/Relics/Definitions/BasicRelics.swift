// MARK: - Basic Relic Definitions

// ============================================================
// Burning Blood (燃烧之血) - Ironclad Starter
// ============================================================

/// 燃烧之血（铁甲战士起始遗物）
/// 效果：战斗胜利后恢复 6 点生命值
public struct BurningBloodRelic: RelicDefinition {
    public static let id: RelicID = "burning_blood"
    public static let name = "燃烧之血"
    public static let description = "战斗胜利后恢复 6 点生命值"
    public static let rarity: RelicRarity = .starter
    public static let icon = "🔥"
    
    public static func onBattleTrigger(_ trigger: BattleTrigger, snapshot: BattleSnapshot) -> [BattleEffect] {
        guard case .battleEnd(let won) = trigger, won else { return [] }
        return [.heal(target: .player, amount: 6)]
    }
}

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
