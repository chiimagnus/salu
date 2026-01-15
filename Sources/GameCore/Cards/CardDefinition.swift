// MARK: - Card Types & Rarity

/// 卡牌类型
public enum CardType: String, Sendable {
    case attack = "攻击"
    case skill = "技能"
    case power = "能力"
    case consumable = "消耗性"
}

/// 卡牌稀有度
public enum CardRarity: String, Sendable {
    case starter = "起始"
    case common = "普通"
    case uncommon = "罕见"
    case rare = "稀有"
}

// MARK: - Card Definition Protocol

/// 战斗快照（卡牌效果决策所需的上下文）
public struct BattleSnapshot: Sendable {
    public let turn: Int
    public let player: Entity
    public let enemies: [Entity]
    public let energy: Int
    
    public init(turn: Int, player: Entity, enemies: [Entity], energy: Int) {
        self.turn = turn
        self.player = player
        self.enemies = enemies
        self.energy = energy
    }
}

/// 卡牌目标需求
public enum CardTargeting: Sendable, Equatable {
    /// 不需要目标（如防御/能力）
    case none
    /// 需要选择一个敌人目标（单体攻击）
    case singleEnemy
}

/// 卡牌定义协议
/// 约束：定义只产出效果，不直接改状态、不直接 emit 事件
public protocol CardDefinition: Sendable {
    /// 卡牌 ID
    static var id: CardID { get }
    
    /// 显示名称（用于 UI）
    static var name: String { get }
    
    /// 卡牌类型
    static var type: CardType { get }
    
    /// 稀有度
    static var rarity: CardRarity { get }
    
    /// 能量消耗
    static var cost: Int { get }
    
    /// 规则文本（UI 展示文本，替代 BattleScreen 的 switch）
    static var rulesText: String { get }
    
    /// 升级版 ID（如果有升级版）
    static var upgradedId: CardID? { get }
    
    /// 目标需求（用于输入校验与 UI 提示）
    static var targeting: CardTargeting { get }
    
    /// 出牌效果（纯决策：输入是快照+目标，输出是效果）
    static func play(snapshot: BattleSnapshot, targetEnemyIndex: Int?) -> [BattleEffect]
}

// 默认实现
extension CardDefinition {
    public static var upgradedId: CardID? { nil }
    
    public static var targeting: CardTargeting {
        type == .attack ? .singleEnemy : .none
    }
}
