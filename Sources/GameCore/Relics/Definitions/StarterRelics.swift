// MARK: - Starter Relic Definitions

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


