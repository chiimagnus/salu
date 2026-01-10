// MARK: - Boss Relic Definitions (P7)

// ============================================================
// Colossus Core (巨像核心) - Boss
// ============================================================

/// 始祖碎片
/// 效果：序列始祖的一部分。战斗开始时，使所有敌人获得中毒 3
public struct ColossusCoreRelic: RelicDefinition {
    public static let id: RelicID = "colossus_core"
    public static let name = "始祖碎片"
    public static let description = "序列始祖的一部分。战斗开始时，使所有敌人获得中毒 3。"
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


