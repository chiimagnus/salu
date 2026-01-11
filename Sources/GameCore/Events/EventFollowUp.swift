/// 事件选项的二次选择（P5：事件系统完善）
public enum EventFollowUp: Sendable, Equatable {
    /// 选择一张可升级卡牌（传入牌组索引列表）
    case chooseUpgradeableCard(indices: [Int])
    
    /// 进入一场精英战斗（由 CLI 侧执行战斗流程与奖励链路）
    case startEliteBattle(enemyId: EnemyID)
}


