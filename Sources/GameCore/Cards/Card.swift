/// 卡牌模型
/// 表示一张具体的卡牌实例
public struct Card: Identifiable, Sendable {
    public let id: String
    public let kind: CardKind
    
    /// 能量消耗
    public var cost: Int {
        switch kind {
        case .strike, .defend, .pommelStrike, .shrugItOff, .inflame:
            return 1
        case .bash, .clothesline:
            return 2
        }
    }
    
    /// 伤害值（仅攻击牌有效）
    public var damage: Int {
        switch kind {
        case .strike: return 6
        case .pommelStrike: return 9
        case .bash: return 8
        case .clothesline: return 12
        case .defend, .shrugItOff, .inflame: return 0
        }
    }
    
    /// 格挡值（仅防御牌有效）
    public var block: Int {
        switch kind {
        case .defend: return 5
        case .shrugItOff: return 8
        case .strike, .pommelStrike, .bash, .inflame, .clothesline: return 0
        }
    }
    
    /// 抽牌数
    public var drawCount: Int {
        switch kind {
        case .pommelStrike, .shrugItOff: return 1
        case .strike, .defend, .bash, .inflame, .clothesline: return 0
        }
    }
    
    /// 施加易伤回合数
    public var vulnerableApply: Int {
        switch kind {
        case .bash: return 2
        default: return 0
        }
    }
    
    /// 施加虚弱回合数
    public var weakApply: Int {
        switch kind {
        case .clothesline: return 2
        default: return 0
        }
    }
    
    /// 获得力量值
    public var strengthGain: Int {
        switch kind {
        case .inflame: return 2
        default: return 0
        }
    }
    
    /// 显示名称
    public var displayName: String {
        switch kind {
        case .strike: return "Strike"
        case .defend: return "Defend"
        case .pommelStrike: return "Pommel Strike"
        case .shrugItOff: return "Shrug It Off"
        case .bash: return "Bash"
        case .inflame: return "Inflame"
        case .clothesline: return "Clothesline"
        }
    }
    
    public init(id: String, kind: CardKind) {
        self.id = id
        self.kind = kind
    }
}

