/// 战斗效果（统一指令）
/// 卡牌/敌人/状态/遗物都只产出 BattleEffect，由 BattleEngine 统一执行并发事件。

public enum EffectTarget: Sendable, Equatable {
    case player
    case enemy
}

public enum BattleEffect: Sendable, Equatable {
    /// 造成伤害（最终伤害由引擎应用伤害修正后结算）
    case dealDamage(target: EffectTarget, base: Int)
    
    /// 获得格挡
    case gainBlock(target: EffectTarget, amount: Int)
    
    /// 抽牌
    case drawCards(count: Int)
    
    /// 获得能量
    case gainEnergy(amount: Int)
    
    /// 施加状态（P1 暂时映射到 Entity 的硬编码字段；P2 会接入 StatusRegistry）
    case applyStatus(target: EffectTarget, statusId: StatusID, stacks: Int)
    
    /// 治疗
    case heal(target: EffectTarget, amount: Int)
}


