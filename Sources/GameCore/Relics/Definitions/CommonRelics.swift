// MARK: - Common Relic Definitions (P7)

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


