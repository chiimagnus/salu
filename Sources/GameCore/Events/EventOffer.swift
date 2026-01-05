/// 事件实例（P5）
///
/// - Note: 事件在进入房间时生成一次，包含可选项与每个选项的确定性效果。
public struct EventOffer: Sendable, Equatable {
    public let eventId: EventID
    public let name: String
    public let icon: String
    public let description: String
    public let options: [EventOption]
    
    public init(eventId: EventID, name: String, icon: String, description: String, options: [EventOption]) {
        self.eventId = eventId
        self.name = name
        self.icon = icon
        self.description = description
        self.options = options
    }
}


