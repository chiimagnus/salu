// MARK: - Encounter System (P6)

/// 一次敌人遭遇（可以包含多个敌人）
public struct EnemyEncounter: Sendable, Equatable {
    public let enemyIds: [EnemyID]
    
    public init(enemyIds: [EnemyID]) {
        precondition(!enemyIds.isEmpty, "EnemyEncounter: enemyIds 不能为空")
        self.enemyIds = enemyIds
    }
}

/// Act 1 遭遇池（可复现：所有随机必须来自注入 rng）
public enum Act1EncounterPool {
    /// 普通战斗（弱遭遇）
    ///
    /// - Note: 至少包含一个“双敌人”遭遇，用于 P6 多敌人战斗验证。
    public static let weak: [EnemyEncounter] = [
        EnemyEncounter(enemyIds: ["jaw_worm"]),
        EnemyEncounter(enemyIds: ["cultist"]),
        EnemyEncounter(enemyIds: ["louse_green"]),
        EnemyEncounter(enemyIds: ["louse_red"]),
        EnemyEncounter(enemyIds: ["spore_beast"]),
        EnemyEncounter(enemyIds: ["slime_small_acid"]),
        
        // 多敌人遭遇（P6：目标选择；P7：内容扩充）
        EnemyEncounter(enemyIds: ["louse_green", "louse_red"]),
        EnemyEncounter(enemyIds: ["cultist", "cultist"]),
        EnemyEncounter(enemyIds: ["jaw_worm", "louse_green"]),
        EnemyEncounter(enemyIds: ["spore_beast", "slime_small_acid"]),
    ]
    
    /// 随机选择弱遭遇（可复现）
    public static func randomWeak(rng: inout SeededRNG) -> EnemyEncounter {
        let index = rng.nextInt(upperBound: weak.count)
        return weak[index]
    }
}


