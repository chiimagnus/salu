/// 事件选项（P5）
public struct EventOption: Sendable, Equatable {
    /// 选项标题（玩家可见）
    public let title: String
    
    /// 选项预览（玩家在选择前可见；例如“获得 50 金币 / 失去 8 HP”）
    public let preview: String?
    
    /// 选择该选项后产生的效果列表
    public let effects: [RunEffect]
    
    public init(title: String, preview: String? = nil, effects: [RunEffect]) {
        self.title = title
        self.preview = preview
        self.effects = effects
    }
}


