/// 战斗待处理输入（GameCore）
///
/// 当战斗流程需要玩家进一步输入（例如“预知选牌”）时，会通过该类型向上层（CLI/UI）暴露。
public enum BattlePendingInput: Sendable, Equatable {
    /// 预知：展示抽牌堆顶 `fromCount` 张牌（顺序：从顶部开始），玩家选择其中 1 张入手
    case foresight(options: [Card], fromCount: Int)
}

