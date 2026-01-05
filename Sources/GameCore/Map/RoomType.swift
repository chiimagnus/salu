/// 房间类型
/// 定义地图上不同类型的房间节点
public enum RoomType: String, Sendable, Equatable, CaseIterable {
    case start = "start"        // 起点
    case battle = "battle"      // 普通战斗
    case elite = "elite"        // 精英战斗
    case rest = "rest"          // 休息点
    case shop = "shop"          // 商店
    case boss = "boss"          // Boss
    
    /// 显示名称
    public var displayName: String {
        switch self {
        case .start: return "起点"
        case .battle: return "战斗"
        case .elite: return "精英"
        case .rest: return "休息"
        case .shop: return "商店"
        case .boss: return "Boss"
        }
    }
    
    /// 显示图标
    public var icon: String {
        switch self {
        case .start: return "🚪"
        case .battle: return "⚔️"
        case .elite: return "💀"
        case .rest: return "💤"
        case .shop: return "🏪"
        case .boss: return "👹"
        }
    }
}
