/// 战斗工具函数
/// 包含伤害计算等共享逻辑

/// 计算最终伤害（应用力量、虚弱、易伤修正）
/// - Parameters:
///   - baseDamage: 基础伤害值
///   - attacker: 攻击者实体
///   - defender: 防御者实体
/// - Returns: 最终伤害值
public func calculateDamage(baseDamage: Int, attacker: Entity, defender: Entity) -> Int {
    var damage = baseDamage
    
    // 力量加成
    damage += attacker.strength
    
    // 虚弱减伤（-25%，向下取整）
    if attacker.weak > 0 {
        damage = Int(Double(damage) * 0.75)
    }
    
    // 易伤增伤（+50%，向下取整）
    if defender.vulnerable > 0 {
        damage = Int(Double(damage) * 1.5)
    }
    
    return max(0, damage)
}
