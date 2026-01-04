/// 卡牌奖励候选
public struct CardRewardOffer: Sendable, Equatable {
    /// 候选卡牌（长度期望为 3；保证去重）
    public let choices: [CardID]
    
    /// 是否允许跳过
    public let canSkip: Bool
    
    public init(choices: [CardID], canSkip: Bool = true) {
        self.choices = choices
        self.canSkip = canSkip
    }
}


