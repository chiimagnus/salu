/// 玩家动作
public enum PlayerAction: Sendable, Equatable {
    /// 打出指定索引的手牌（0-based）
    case playCard(handIndex: Int)
    
    /// 结束回合
    case endTurn
}

