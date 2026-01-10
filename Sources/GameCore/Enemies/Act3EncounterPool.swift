// MARK: - Act 3 Encounter System

/// Act 3 遭遇池（可复现：所有随机必须来自注入 rng）
public enum Act3EncounterPool {
    /// 普通战斗（弱遭遇）
    public static let weak: [EnemyEncounter] = [
        EnemyEncounter(enemyIds: ["void_walker"]),
        EnemyEncounter(enemyIds: ["dream_parasite"]),
        
        // 多敌人遭遇
        EnemyEncounter(enemyIds: ["void_walker", "dream_parasite"]),
        EnemyEncounter(enemyIds: ["dream_parasite", "dream_parasite"]),
        EnemyEncounter(enemyIds: ["void_walker", "void_walker"]),
    ]
    
    /// 随机选择弱遭遇（可复现）
    public static func randomWeak(rng: inout SeededRNG) -> EnemyEncounter {
        let index = rng.nextInt(upperBound: weak.count)
        return weak[index]
    }
}

