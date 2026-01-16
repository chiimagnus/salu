// MARK: - Consumable Cards (消耗性卡牌, P4R)
//
// 破坏性重构：消耗品并入卡牌系统，作为一种新的 CardType（.consumable）。
// 规则：
// - cost 恒为 0（不耗能量）
// - 打出后为“一次性”：本战斗不再出现，并且会从 RunState.deck 永久移除（由 CLI 驱动移除实例）

// ============================================================
// Healing Potion (治疗药剂) - Common
// ============================================================

/// 治疗药剂
/// 消耗性卡牌：恢复 20 点生命值
public struct HealingPotion: CardDefinition {
    public static let id: CardID = "healing_potion"
    public static let name = LocalizedText("治疗药剂", "Healing Potion")
    public static let type: CardType = .consumable
    public static let rarity: CardRarity = .common
    public static let cost = 0
    public static let rulesText = LocalizedText(
        "暗红色的液体，带着铁锈般的腥味。恢复 20 点生命值。",
        "A dark red liquid with a rusty tang. Restore 20 HP."
    )

    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        _ = snapshot
        _ = targetEnemyIndex
        return [.heal(target: .player, amount: 20)]
    }
}

// ============================================================
// Block Potion (格挡药剂) - Common
// ============================================================

/// 格挡药剂
/// 消耗性卡牌：获得 12 点格挡
public struct BlockPotion: CardDefinition {
    public static let id: CardID = "block_potion"
    public static let name = LocalizedText("格挡药剂", "Block Potion")
    public static let type: CardType = .consumable
    public static let rarity: CardRarity = .common
    public static let cost = 0
    public static let rulesText = LocalizedText(
        "淡蓝色的药液，喝下后皮肤短暂硬化。获得 12 点格挡。",
        "A pale blue brew that hardens the skin. Gain 12 Block."
    )

    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        _ = snapshot
        _ = targetEnemyIndex
        return [.gainBlock(target: .player, base: 12)]
    }
}

// ============================================================
// Strength Potion (力量药剂) - Uncommon
// ============================================================

/// 力量药剂
/// 消耗性卡牌：获得 2 点力量
public struct StrengthPotion: CardDefinition {
    public static let id: CardID = "strength_potion"
    public static let name = LocalizedText("力量药剂", "Strength Potion")
    public static let type: CardType = .consumable
    public static let rarity: CardRarity = .uncommon
    public static let cost = 0
    public static let rulesText = LocalizedText(
        "深红色的浓稠液体，散发着血腥的气息。获得 2 点力量。",
        "A thick crimson liquid that reeks of blood. Gain 2 Strength."
    )

    public static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect] {
        _ = snapshot
        _ = targetEnemyIndex
        return [.applyStatus(target: .player, statusId: Strength.id, stacks: 2)]
    }
}
