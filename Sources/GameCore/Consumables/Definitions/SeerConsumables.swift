// MARK: - Seer Sequence Consumable Definitions (占卜家序列消耗品)

// ============================================================
// Purification Rune (净化符文) - Uncommon
// ============================================================

/// 净化符文
/// 效果：清除所有疯狂
/// 风味：「符文燃烧的瞬间，所有杂念都随之消散。」
public struct PurificationRuneConsumable: ConsumableDefinition {
    public static let id: ConsumableID = "purification_rune"
    public static let name = "净化符文"
    public static let description = "符文燃烧的瞬间，所有杂念都随之消散。清除所有疯狂。"
    public static let rarity: ConsumableRarity = .uncommon
    public static let icon = "📿"
    
    public static let usableInBattle = true
    public static let usableOutsideBattle = false
    
    public static func useInBattle(snapshot: BattleSnapshot) -> [BattleEffect] {
        return [.clearMadness(amount: 0)]  // amount: 0 表示清除所有
    }
}
