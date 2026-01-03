/// 房间类型
/// 定义地图中不同类型的房间
public enum RoomType: String, Sendable {
    case battle = "⚔️"      // 战斗房间
    case rest = "🔥"        // 休息房间
    case boss = "👹"        // Boss 房间
    
    /// 显示名称
    public var displayName: String {
        switch self {
        case .battle: return "战斗"
        case .rest: return "休息"
        case .boss: return "Boss"
        }
    }
}
