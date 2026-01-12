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
    
    // MARK: - 占卜家序列效果 (P1)
    
    /// 预知：查看抽牌堆顶 N 张，选 1 张入手，其余原顺序放回
    /// - Parameters:
    ///   - count: 预知数量
    case foresight(count: Int)
    
    /// 回溯：从弃牌堆选取最近 N 张牌返回手牌
    /// - Parameters:
    ///   - count: 回溯数量
    case rewind(count: Int)
    
    /// 清除疯狂
    /// - Parameters:
    ///   - amount: 清除数量（0 表示清除所有）
    case clearMadness(amount: Int)
    
    /// 改写敌人意图
    /// - Parameters:
    ///   - enemyIndex: 目标敌人索引
    ///   - newIntent: 新的意图类型
    case rewriteIntent(enemyIndex: Int, newIntent: RewrittenIntent)

    // MARK: - 赛弗 Boss 特殊机制 (P6)

    /// 预知反制：下回合玩家预知数量 -amount（最低为 0）
    case applyForesightPenaltyNextTurn(amount: Int)

    /// 命运改写（敌方版）：下回合玩家第一张牌费用 +amount
    case applyFirstCardCostIncreaseNextTurn(amount: Int)

    /// 随机弃置手牌
    case discardRandomHand(count: Int)

    /// 敌人回复（用于 Boss “时间回溯”等）
    case enemyHeal(enemyIndex: Int, amount: Int)

    // MARK: - 占卜家卡牌扩展 (P7)

    /// 造成伤害：伤害值 = basePerForesight × 本回合预知次数
    case dealDamageBasedOnForesightCount(source: EffectTarget, target: EffectTarget, basePerForesight: Int)
}
