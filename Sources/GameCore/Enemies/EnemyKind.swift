/// 敌人种类
/// 每种敌人有唯一标识符和显示名称
public enum EnemyKind: String, CaseIterable, Sendable {
    case jawWorm = "jaw_worm"
    case cultist = "cultist"
    case louseGreen = "louse_green"
    case louseRed = "louse_red"
    case slimeMediumAcid = "slime_medium_acid"
    
    /// 显示名称
    public var displayName: String {
        switch self {
        case .jawWorm: return "下颚虫"
        case .cultist: return "信徒"
        case .louseGreen: return "绿虱子"
        case .louseRed: return "红虱子"
        case .slimeMediumAcid: return "酸液史莱姆"
        }
    }
}

