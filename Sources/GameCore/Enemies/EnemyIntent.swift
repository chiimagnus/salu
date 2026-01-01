/// 敌人意图类型
public enum EnemyIntent: Sendable, Equatable {
    case attack(damage: Int)
    case attackDebuff(damage: Int, debuff: String, stacks: Int)
    case defend(block: Int)
    case buff(buff: String, stacks: Int)
    case unknown
    
    /// 用于 UI 显示
    public var displayIcon: String {
        switch self {
        case .attack: return "⚔️"
        case .attackDebuff: return "⚔️💀"
        case .defend: return "🛡️"
        case .buff: return "💪"
        case .unknown: return "❓"
        }
    }
    
    /// 用于 UI 显示的描述
    public var displayText: String {
        switch self {
        case .attack(let damage):
            return "攻击 \(damage) 伤害"
        case .attackDebuff(let damage, let debuff, let stacks):
            return "攻击 \(damage) + \(debuff) \(stacks)"
        case .defend(let block):
            return "防御 \(block)"
        case .buff(let buff, let stacks):
            return "\(buff) +\(stacks)"
        case .unknown:
            return "???"
        }
    }
}
