/// 事件选项（P5）
public struct EventOption: Sendable, Equatable {
    /// 选项标题（玩家可见）
    public let title: String
    
    /// 选项预览（玩家在选择前可见；例如“获得 50 金币 / 失去 8 HP”）
    public let preview: String?
    
    /// 选择该选项后产生的效果列表
    public let effects: [RunEffect]

    /// 需要二次选择时的附加信息（例如：选择要升级的卡牌）
    public let followUp: EventFollowUp?
    
    public init(title: String, preview: String? = nil, effects: [RunEffect], followUp: EventFollowUp? = nil) {
        self.title = title
        self.preview = preview
        self.effects = effects
        self.followUp = followUp
    }
}


