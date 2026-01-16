// MARK: - Boss Relic Definitions (P7)

// ============================================================
// Colossus Core (巨像核心) - Boss
// ============================================================

/// 始祖碎片
/// 效果：序列始祖的一部分。战斗开始时，使所有敌人获得中毒 3
public struct ColossusCoreRelic: RelicDefinition {
    public static let id: RelicID = "colossus_core"
    public static let name = LocalizedText("始祖碎片", "Progenitor Fragment")
    public static let description = LocalizedText(
        "序列始祖的一部分。战斗开始时，使所有敌人获得中毒 3。",
        "A piece of the Sequence Progenitor. At battle start, apply 3 Poison to all enemies."
    )
    public static let rarity: RelicRarity = .boss
    public static let icon = "🧪"
    
    public static func onBattleTrigger(_ trigger: BattleTrigger, snapshot: BattleSnapshot) -> [BattleEffect] {
        guard case .battleStart = trigger else { return [] }
        
        return snapshot.enemies.enumerated().compactMap { index, enemy in
            guard enemy.isAlive else { return nil }
            return .applyStatus(target: .enemy(index: index), statusId: "poison", stacks: 3)
        }
    }
}

