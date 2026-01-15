// MARK: - Seer Consumable Cards (占卜家消耗性卡牌, P4R)

// ============================================================
// Purification Rune (净化符文) - Rare
// ============================================================

/// 净化符文
/// 消耗性卡牌：清除所有疯狂（等价于清除状态 Madness）
public struct PurificationRune: CardDefinition {
    public static let id: CardID = "purification_rune"
    public static let name = "净化符文"
    public static let type: CardType = .consumable
    public static let rarity: CardRarity = .rare
    public static let cost = 0
    public static let rulesText = "以符文净化心智。清除所有疯狂。"

    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        _ = snapshot
        _ = targetEnemyIndex
        return [.clearMadness(amount: 0)]
    }
}

