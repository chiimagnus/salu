// MARK: - Battle Effect System

/// 效果目标
public enum EffectTarget: Sendable, Equatable {
    case player
    /// 多敌人场景下，用索引指向“战斗中的某个敌人实例”
    case enemy(index: Int)
}

/// 战斗效果（统一效果枚举：卡牌/状态/遗物/敌人都用）
/// 约束：定义层只产出 Effect 描述，不直接改 BattleState
/// 只有 Engine（BattleEngine）能执行效果并发出事件
public enum BattleEffect: Sendable, Equatable {
    /// 造成伤害（base 值，不含修正）
    case dealDamage(source: EffectTarget, target: EffectTarget, base: Int)
    
    /// 获得格挡（base 值，不含修正）
    case gainBlock(target: EffectTarget, base: Int)
    
    /// 抽牌
    case drawCards(count: Int)
    
    /// 获得能量
    case gainEnergy(amount: Int)
    
    /// 施加状态（如易伤、虚弱、力量等）
    case applyStatus(target: EffectTarget, statusId: StatusID, stacks: Int)
    
    /// 治疗（用于遗物等）
    case heal(target: EffectTarget, amount: Int)
}
