// MARK: - Card Types

/// 卡牌种类
public enum CardKind: String, Sendable {
    case strike  // 攻击牌：1能量，造成6伤害
    case defend  // 防御牌：1能量，获得5格挡
}

/// 卡牌
public struct Card: Identifiable, Sendable {
    public let id: String
    public let kind: CardKind
    
    /// 能量消耗
    public var cost: Int {
        switch kind {
        case .strike: return 1
        case .defend: return 1
        }
    }
    
    /// 伤害值（仅攻击牌有效）
    public var damage: Int {
        switch kind {
        case .strike: return 6
        case .defend: return 0
        }
    }
    
    /// 格挡值（仅防御牌有效）
    public var block: Int {
        switch kind {
        case .strike: return 0
        case .defend: return 5
        }
    }
    
    /// 显示名称
    public var displayName: String {
        switch kind {
        case .strike: return "Strike"
        case .defend: return "Defend"
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
    
    public var isAlive: Bool {
        currentHP > 0
    }
    
    public init(id: String, name: String, maxHP: Int) {
        self.id = id
        self.name = name
        self.maxHP = maxHP
        self.currentHP = maxHP
        self.block = 0
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
    
    // 5 张 Strike
    for i in 1...5 {
        cards.append(Card(id: "strike_\(i)", kind: .strike))
    }
    
    // 5 张 Defend
    for i in 1...5 {
        cards.append(Card(id: "defend_\(i)", kind: .defend))
    }
    
    return cards
}

/// 创建默认玩家
public func createDefaultPlayer() -> Entity {
    Entity(id: "player", name: "铁甲战士", maxHP: 80)
}

/// 创建默认敌人
public func createDefaultEnemy() -> Entity {
    Entity(id: "enemy", name: "下颚虫", maxHP: 42)
}

