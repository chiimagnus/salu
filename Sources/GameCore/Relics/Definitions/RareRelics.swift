// MARK: - Rare Relic Definitions (P7)

// ============================================================
// War Banner (战旗) - Rare
// ============================================================

/// 战旗
/// 效果：战斗开始时获得 2 点力量
public struct WarBannerRelic: RelicDefinition {
    public static let id: RelicID = "war_banner"
    public static let name = "战旗"
    public static let description = "战斗开始时获得 2 点力量"
    public static let rarity: RelicRarity = .rare
    public static let icon = "🚩"
    
    public static func onBattleTrigger(_ trigger: BattleTrigger, snapshot: BattleSnapshot) -> [BattleEffect] {
        guard case .battleStart = trigger else { return [] }
        return [.applyStatus(target: .player, statusId: "strength", stacks: 2)]
    }
}


