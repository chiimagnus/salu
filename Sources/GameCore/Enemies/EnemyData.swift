/// 敌人静态数据
public struct EnemyData: Sendable {
    public let kind: EnemyKind
    public let minHP: Int
    public let maxHP: Int
    public let baseAttackDamage: Int
    
    /// 获取敌人数据
    public static func get(_ kind: EnemyKind) -> EnemyData {
        switch kind {
        case .jawWorm:
            return EnemyData(kind: kind, minHP: 40, maxHP: 44, baseAttackDamage: 11)
        case .cultist:
            return EnemyData(kind: kind, minHP: 48, maxHP: 54, baseAttackDamage: 6)
        case .louseGreen:
            return EnemyData(kind: kind, minHP: 11, maxHP: 17, baseAttackDamage: 6)
        case .louseRed:
            return EnemyData(kind: kind, minHP: 10, maxHP: 15, baseAttackDamage: 6)
        case .slimeMediumAcid:
            return EnemyData(kind: kind, minHP: 28, maxHP: 32, baseAttackDamage: 10)
        }
    }
    
    /// 根据 RNG 生成实际 HP
    public func generateHP(rng: inout SeededRNG) -> Int {
        return minHP + rng.nextInt(upperBound: maxHP - minHP + 1)
    }
}
