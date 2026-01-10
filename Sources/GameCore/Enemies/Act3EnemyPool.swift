// MARK: - Act 3 Enemy Pool

/// 第三章敌人池（Act3）
/// 管理不同难度的敌人遭遇
public enum Act3EnemyPool {
    /// 弱敌人（普通战斗）
    public static let weak: [EnemyID] = [
        "void_walker",
        "dream_parasite",
    ]
    
    /// 中等敌人（精英战斗）
    public static let medium: [EnemyID] = [
        "cycle_guardian",
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
}

