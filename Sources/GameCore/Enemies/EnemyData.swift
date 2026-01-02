/// 敌人静态数据
/// 包含 HP 范围、基础攻击力等属性
public struct EnemyData: Sendable {
    public let kind: EnemyKind
    public let minHP: Int
    public let maxHP: Int
    public let baseAttackDamage: Int
    
    public init(kind: EnemyKind, minHP: Int, maxHP: Int, baseAttackDamage: Int) {
        self.kind = kind
        self.minHP = minHP
        self.maxHP = maxHP
        self.baseAttackDamage = baseAttackDamage
    }
    
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
        let range = maxHP - minHP + 1
        return minHP + rng.nextInt(upperBound: range)
    }
}

