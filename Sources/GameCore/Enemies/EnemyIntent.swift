/// 敌人意图类型
/// 描述敌人下一回合将执行的行动
public enum EnemyIntent: Sendable, Equatable {
    /// 纯攻击
    case attack(damage: Int)
    
    /// 攻击 + 施加 Debuff
    case attackDebuff(damage: Int, debuff: String, stacks: Int)
    
    /// 纯防御
    case defend(block: Int)
    
    /// 增益（给自己加 Buff）
    case buff(name: String, stacks: Int)
    
    /// 未知意图
    case unknown
    
    // MARK: - UI 显示
    
    /// 显示图标
    public var displayIcon: String {
        switch self {
        case .attack: return "⚔️"
        case .attackDebuff: return "⚔️💀"
        case .defend: return "🛡️"
        case .buff: return "💪"
        case .unknown: return "❓"
        }
    }
    
    /// 显示文本
    public var displayText: String {
        switch self {
        case .attack(let damage):
            return "攻击 \(damage)"
        case .attackDebuff(let damage, let debuff, _):
            return "攻击 \(damage) + \(debuff)"
        case .defend(let block):
            return "防御 \(block)"
        case .buff(let name, let stacks):
            return "\(name) +\(stacks)"
        case .unknown:
            return "???"
        }
    }
    
    /// 获取意图中的伤害值（用于 UI 显示）
    public var damageValue: Int? {
        switch self {
        case .attack(let damage):
            return damage
        case .attackDebuff(let damage, _, _):
            return damage
        default:
            return nil
        }
    }
}

