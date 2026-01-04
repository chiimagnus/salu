// MARK: - Battle Trigger System

/// 战斗触发点（只包含 battle 相关）
/// 说明：run 相关触发点（进入房间/获得金币等）会在 P5/P6 的 RunEngine 中定义 RunTrigger/RunEffect
public enum BattleTrigger: Sendable, Equatable {
    /// 战斗开始
    case battleStart
    
    /// 战斗结束
    case battleEnd(won: Bool)
    
    /// 回合开始
    case turnStart(turn: Int)
    
    /// 回合结束
    case turnEnd(turn: Int)
    
    /// 打出卡牌
    case cardPlayed(cardId: CardID)
    
    /// 抽到卡牌
    case cardDrawn(cardId: CardID)
    
    /// 造成伤害
    case damageDealt(amount: Int)
    
    /// 受到伤害
    case damageTaken(amount: Int)
    
    /// 获得格挡
    case blockGained(amount: Int)
    
    /// 敌人被击杀
    case enemyKilled
}
