// MARK: - Card Types

/// 卡牌种类
public enum CardKind: String, Sendable {
    case strike         // 攻击牌：1能量，造成6伤害
    case defend         // 防御牌：1能量，获得5格挡
    case pommelStrike   // 柄击：1能量，造成9伤害，抽1张牌
    case shrugItOff     // 耸肩：1能量，获得8格挡，抽1张牌
    case bash           // 重击：2能量，造成8伤害，给予易伤2
    case inflame        // 燃烧：1能量，获得2力量
    case clothesline    // 晾衣绳：2能量，造成12伤害，给予虚弱2
}

/// 卡牌
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

// MARK: - Entity

/// 战斗实体（玩家或敌人）
public struct Entity: Sendable {
    public let id: String
    public let name: String
    public let maxHP: Int
    public var currentHP: Int
    public var block: Int
    
    // 状态效果（回合数）
    public var vulnerable: Int = 0   // 易伤：受到伤害 +50%
    public var weak: Int = 0         // 虚弱：造成伤害 -25%
    public var strength: Int = 0     // 力量：攻击伤害 +N
    
    public var isAlive: Bool {
        currentHP > 0
    }
    
    /// 是否有任何状态效果
    public var hasAnyStatus: Bool {
        vulnerable > 0 || weak > 0 || strength != 0
    }
    
    public init(id: String, name: String, maxHP: Int) {
        self.id = id
        self.name = name
        self.maxHP = maxHP
        self.currentHP = maxHP
        self.block = 0
        self.vulnerable = 0
        self.weak = 0
        self.strength = 0
    }
    
    /// 回合结束时递减状态效果
    /// - Returns: 过期的状态效果列表
    public mutating func tickStatusEffects() -> [String] {
        var expired: [String] = []
        
        if vulnerable > 0 {
            vulnerable -= 1
            if vulnerable == 0 {
                expired.append("易伤")
            }
        }
        
        if weak > 0 {
            weak -= 1
            if weak == 0 {
                expired.append("虚弱")
            }
        }
        
        // strength 不递减（永久效果）
        
        return expired
    }
    
    /// 受到伤害（先扣格挡再扣血）
    /// - Returns: (实际伤害, 被格挡的伤害)
    public mutating func takeDamage(_ amount: Int) -> (dealt: Int, blocked: Int) {
        guard amount > 0 else { return (0, 0) }
        
        let blockedDamage = min(block, amount)
        block -= blockedDamage
        
        let remainingDamage = amount - blockedDamage
        currentHP = max(0, currentHP - remainingDamage)
        
        return (remainingDamage, blockedDamage)
    }
    
    /// 获得格挡
    public mutating func gainBlock(_ amount: Int) {
        guard amount > 0 else { return }
        block += amount
    }
    
    /// 清除格挡（每回合开始时调用）
    public mutating func clearBlock() {
        block = 0
    }
}

// MARK: - Battle State

/// 战斗状态
public struct BattleState: Sendable {
    public var player: Entity
    public var enemy: Entity
    
    public var energy: Int
    public let maxEnergy: Int
    
    public var turn: Int
    public var isPlayerTurn: Bool
    
    public var drawPile: [Card]
    public var hand: [Card]
    public var discardPile: [Card]
    
    public var isOver: Bool
    public var playerWon: Bool?
    
    public init(
        player: Entity,
        enemy: Entity,
        maxEnergy: Int = 3
    ) {
        self.player = player
        self.enemy = enemy
        self.energy = maxEnergy
        self.maxEnergy = maxEnergy
        self.turn = 0
        self.isPlayerTurn = true
        self.drawPile = []
        self.hand = []
        self.discardPile = []
        self.isOver = false
        self.playerWon = nil
    }
}

// MARK: - Card Factory

/// 创建初始牌组
public func createStarterDeck() -> [Card] {
    var cards: [Card] = []
    
    // 4 张 Strike
    for i in 1...4 {
        cards.append(Card(id: "strike_\(i)", kind: .strike))
    }
    
    // 4 张 Defend
    for i in 1...4 {
        cards.append(Card(id: "defend_\(i)", kind: .defend))
    }
    
    // 1 张 Bash（起始牌）
    cards.append(Card(id: "bash_1", kind: .bash))
    
    // 1 张 Pommel Strike
    cards.append(Card(id: "pommelStrike_1", kind: .pommelStrike))
    
    // 1 张 Shrug It Off
    cards.append(Card(id: "shrugItOff_1", kind: .shrugItOff))
    
    // 1 张 Inflame
    cards.append(Card(id: "inflame_1", kind: .inflame))
    
    // 1 张 Clothesline
    cards.append(Card(id: "clothesline_1", kind: .clothesline))
    
    return cards  // 总计 13 张
}

/// 创建默认玩家
public func createDefaultPlayer() -> Entity {
    Entity(id: "player", name: "铁甲战士", maxHP: 80)
}

/// 创建默认敌人
public func createDefaultEnemy() -> Entity {
    Entity(id: "enemy", name: "下颚虫", maxHP: 42)
}

