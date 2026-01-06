// MARK: - Uncommon Relic Definitions (P7)

// ============================================================
// Feather Cloak (羽披风) - Uncommon
// ============================================================

/// 羽披风
/// 效果：战斗开始时获得 1 点敏捷
public struct FeatherCloakRelic: RelicDefinition {
    public static let id: RelicID = "feather_cloak"
    public static let name = "羽披风"
    public static let description = "战斗开始时获得 1 点敏捷"
    public static let rarity: RelicRarity = .uncommon
    public static let icon = "🪶"
    
    public static func onBattleTrigger(_ trigger: BattleTrigger, snapshot: BattleSnapshot) -> [BattleEffect] {
        guard case .battleStart = trigger else { return [] }
        return [.applyStatus(target: .player, statusId: "dexterity", stacks: 1)]
    }
}


