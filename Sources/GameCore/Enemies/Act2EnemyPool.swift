// MARK: - Act 2 Enemy Pool (P7 + P2 占卜家序列扩展)

/// 第二章敌人池（Act2）
/// 管理不同难度的敌人遭遇
public enum Act2EnemyPool {
    /// 弱敌人（普通战斗）
    public static let weak: [EnemyID] = [
        "shadow_stalker",
        "clockwork_sentinel",
    ]
    
    /// 中等敌人（精英战斗）
    /// P2 新增：疯狂预言者、时间守卫
    public static let medium: [EnemyID] = [
        "rune_guardian",
        "mad_prophet",      // P2 占卜家序列
        "time_guardian",    // P2 占卜家序列
    ]
    
    /// Boss（P2：赛弗替换窥视者）
    public static let boss: EnemyID = "cipher"
    
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


