// MARK: - Act 1 Enemy Pool

/// 第一章敌人池（P3: 使用 EnemyID）
/// 管理不同难度的敌人遭遇
public enum Act1EnemyPool {
    /// 弱敌人（前几场战斗）
    public static let weak: [EnemyID] = [
        "jaw_worm", "cultist", "louse_green", "louse_red",
        "spore_beast", "slime_small_acid"
    ]
    
    /// 中等敌人（中期战斗）
    public static let medium: [EnemyID] = [
        "slime_medium_acid", "stone_sentinel"
    ]
    
    /// 所有敌人
    public static let all: [EnemyID] = weak + medium
    
    /// 随机选择弱敌人
    public static func randomWeak(rng: inout SeededRNG) -> EnemyID {
        let index = rng.nextInt(upperBound: weak.count)
        return weak[index]
    }
    
    /// 随机选择中等敌人
    public static func randomMedium(rng: inout SeededRNG) -> EnemyID {
        let index = rng.nextInt(upperBound: medium.count)
        return medium[index]
    }
    
    /// 随机选择任意敌人
    public static func randomAny(rng: inout SeededRNG) -> EnemyID {
        let index = rng.nextInt(upperBound: all.count)
        return all[index]
    }
}

// MARK: - Enemy Factory

/// 创建敌人实体 (P3: 使用 EnemyRegistry)
/// - Parameters:
///   - enemyId: 敌人 ID
///   - instanceIndex: 该敌人在遭遇中的序号（用于生成唯一的实体 id）
///   - rng: 随机数生成器（用于 HP 浮动）
/// - Returns: 敌人实体
public func createEnemy(enemyId: EnemyID, instanceIndex: Int, rng: inout SeededRNG) -> Entity {
    let def = EnemyRegistry.require(enemyId)
    let hpRange = def.hpRange
    let range = hpRange.upperBound - hpRange.lowerBound + 1
    let hp = hpRange.lowerBound + rng.nextInt(upperBound: range)
    
    return Entity(
        id: "\(enemyId.rawValue)#\(instanceIndex)",
        name: def.name,
        maxHP: hp,
        enemyId: enemyId
    )
}


