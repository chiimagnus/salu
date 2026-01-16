/// 事件定义协议（P5）
///
/// 约束：
/// - 事件内容只负责“决策/产出”，不做任何 I/O
/// - 随机必须来自注入的 rng，保证可复现
public protocol EventDefinition: Sendable {
    /// 事件 ID
    static var id: EventID { get }
    
    /// 事件名称（玩家可见）
    static var name: LocalizedText { get }
    
    /// 事件图标（玩家可见）
    static var icon: String { get }
    
    /// 事件描述（玩家可见）
    static var description: LocalizedText { get }
    
    /// 生成本次事件实例（含确定性的选项与效果）
    static func generate(context: EventContext, rng: inout SeededRNG) -> EventOffer
}

