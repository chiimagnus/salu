/// 事件实例（P5）
///
/// - Note: 事件在进入房间时生成一次，包含可选项与每个选项的确定性效果。
public struct EventOffer: Sendable, Equatable {
    public let eventId: EventID
    public let name: LocalizedText
    public let icon: String
    public let description: LocalizedText
    public let options: [EventOption]
    
    public init(
        eventId: EventID,
        name: LocalizedText,
        icon: String,
        description: LocalizedText,
        options: [EventOption]
    ) {
        self.eventId = eventId
        self.name = name
        self.icon = icon
        self.description = description
        self.options = options
    }
}

