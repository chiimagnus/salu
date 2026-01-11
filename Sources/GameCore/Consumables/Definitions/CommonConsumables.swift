// MARK: - Common Consumable Definitions (通用消耗品)

// ============================================================
// Healing Potion (治疗药剂) - Common
// ============================================================

/// 治疗药剂
/// 效果：恢复 20 点生命值
/// 风味：「暗红色的液体，带着铁锈般的腥味。」
public struct HealingPotionConsumable: ConsumableDefinition {
    public static let id: ConsumableID = "healing_potion"
    public static let name = "治疗药剂"
    public static let description = "暗红色的液体，带着铁锈般的腥味。恢复 20 点生命值。"
    public static let rarity: ConsumableRarity = .common
    public static let icon = "🧪"
    
    public static let usableInBattle = true
    public static let usableOutsideBattle = true
    
    public static func useInBattle(snapshot: BattleSnapshot) -> [BattleEffect] {
        return [.heal(target: .player, amount: 20)]
    }
    
    public static func useOutsideBattle() -> [RunEffect] {
        return [.heal(amount: 20)]
    }
}

// ============================================================
// Block Potion (格挡药剂) - Common
// ============================================================

/// 格挡药剂
/// 效果：获得 12 点格挡
/// 风味：「淡蓝色的药液，喝下后皮肤短暂硬化。」
public struct BlockPotionConsumable: ConsumableDefinition {
    public static let id: ConsumableID = "block_potion"
    public static let name = "格挡药剂"
    public static let description = "淡蓝色的药液，喝下后皮肤短暂硬化。获得 12 点格挡。"
    public static let rarity: ConsumableRarity = .common
    public static let icon = "🛡️"
    
    public static let usableInBattle = true
    public static let usableOutsideBattle = false
    
    public static func useInBattle(snapshot: BattleSnapshot) -> [BattleEffect] {
        return [.gainBlock(target: .player, base: 12)]
    }
}

// ============================================================
// Strength Potion (力量药剂) - Uncommon
// ============================================================

/// 力量药剂
/// 效果：获得 2 点力量
/// 风味：「深红色的浓稠液体，散发着血腥的气息。」
public struct StrengthPotionConsumable: ConsumableDefinition {
    public static let id: ConsumableID = "strength_potion"
    public static let name = "力量药剂"
    public static let description = "深红色的浓稠液体，散发着血腥的气息。获得 2 点力量。"
    public static let rarity: ConsumableRarity = .uncommon
    public static let icon = "💪"
    
    public static let usableInBattle = true
    public static let usableOutsideBattle = false
    
    public static func useInBattle(snapshot: BattleSnapshot) -> [BattleEffect] {
        return [.applyStatus(target: .player, statusId: Strength.id, stacks: 2)]
    }
}
