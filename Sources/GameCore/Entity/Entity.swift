/// 战斗实体（玩家或敌人）
/// 包含生命值、格挡、状态效果等属性
public struct Entity: Sendable {
    public let id: String
    public let name: String
    public let maxHP: Int
    public var currentHP: Int
    public var block: Int
    
    // 状态效果容器（P2 重构：使用 StatusContainer）
    public var statuses: StatusContainer = StatusContainer()
    
    /// 敌人种类（仅敌人使用，玩家为 nil）
    public let kind: EnemyKind?
    
    /// 当前意图（仅敌人使用）
    public var intent: EnemyIntent = .unknown
    
    public var isAlive: Bool {
        currentHP > 0
    }
    
    /// 是否有任何状态效果
    public var hasAnyStatus: Bool {
        statuses.hasAny
    }
    
    /// 创建玩家实体
    public init(id: String, name: String, maxHP: Int) {
        self.id = id
        self.name = name
        self.maxHP = maxHP
        self.currentHP = maxHP
        self.block = 0
        self.kind = nil
        self.intent = .unknown
    }
    
    /// 创建敌人实体
    public init(id: String, name: String, maxHP: Int, kind: EnemyKind) {
        self.id = id
        self.name = name
        self.maxHP = maxHP
        self.currentHP = maxHP
        self.block = 0
        self.kind = kind
        self.intent = .unknown
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

// MARK: - Entity Factory

/// 创建默认玩家
public func createDefaultPlayer() -> Entity {
    Entity(id: "player", name: "铁甲战士", maxHP: 80)
}

