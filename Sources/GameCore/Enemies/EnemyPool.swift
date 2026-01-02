/// 第一章敌人池
/// 管理不同难度的敌人遭遇
public enum Act1EnemyPool {
    /// 弱敌人（前几场战斗）
    public static let weak: [EnemyKind] = [
        .jawWorm, .cultist, .louseGreen, .louseRed
    ]
    
    /// 中等敌人（中期战斗）
    public static let medium: [EnemyKind] = [
        .slimeMediumAcid
    ]
    
    /// 所有敌人
    public static let all: [EnemyKind] = weak + medium
    
    /// 随机选择弱敌人
    public static func randomWeak(rng: inout SeededRNG) -> EnemyKind {
        let index = rng.nextInt(upperBound: weak.count)
        return weak[index]
    }
    
    /// 随机选择任意敌人
    public static func randomAny(rng: inout SeededRNG) -> EnemyKind {
        let index = rng.nextInt(upperBound: all.count)
        return all[index]
    }
}

// MARK: - 敌人创建工厂

/// 创建敌人实体
/// - Parameters:
///   - kind: 敌人种类
///   - rng: 随机数生成器（用于 HP 浮动）
/// - Returns: 敌人实体
public func createEnemy(kind: EnemyKind, rng: inout SeededRNG) -> Entity {
    let data = EnemyData.get(kind)
    let hp = data.generateHP(rng: &rng)
    return Entity(
        id: kind.rawValue,
        name: kind.displayName,
        maxHP: hp,
        kind: kind
    )
}

