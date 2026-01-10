// MARK: - Starter Relic Definitions

// ============================================================
// Burning Blood (燃烧之血) - Ironclad Starter
// ============================================================

/// 永燃心脏（安德起始遗物）
/// 效果：不死者的馈赠。战斗胜利后恢复 6 点生命值
public struct BurningBloodRelic: RelicDefinition {
    public static let id: RelicID = "burning_blood"
    public static let name = "永燃心脏"
    public static let description = "不死者的馈赠。战斗胜利后恢复 6 点生命值。"
    public static let rarity: RelicRarity = .starter
    public static let icon = "🔥"
    
    public static func onBattleTrigger(_ trigger: BattleTrigger, snapshot: BattleSnapshot) -> [BattleEffect] {
        guard case .battleEnd(let won) = trigger, won else { return [] }
        return [.heal(target: .player, amount: 6)]
    }
}


