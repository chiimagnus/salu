// MARK: - Act 2 Encounter System (P7)

/// Act 2 遭遇池（可复现：所有随机必须来自注入 rng）
public enum Act2EncounterPool {
    /// 普通战斗（弱遭遇）
    public static let weak: [EnemyEncounter] = [
        EnemyEncounter(enemyIds: ["shadow_stalker"]),
        EnemyEncounter(enemyIds: ["clockwork_sentinel"]),
        
        // 多敌人遭遇
        EnemyEncounter(enemyIds: ["shadow_stalker", "clockwork_sentinel"]),
        EnemyEncounter(enemyIds: ["clockwork_sentinel", "clockwork_sentinel"]),
    ]
    
    /// 随机选择弱遭遇（可复现）
    public static func randomWeak(rng: inout SeededRNG) -> EnemyEncounter {
        let index = rng.nextInt(upperBound: weak.count)
        return weak[index]
    }
}


