/// 卡牌定义协议
/// 每张卡牌对应一个 Definition，描述静态属性与可执行效果（BattleEffect）。

public enum CardType: String, Sendable {
    case attack = "攻击"
    case skill = "技能"
    case power = "能力"
}

public enum CardRarity: String, Sendable {
    case basic = "基础"
    case common = "普通"
    case uncommon = "罕见"
    case rare = "稀有"
}

/// 战斗快照（只读）
/// Definition 只能读快照，不能直接修改战斗状态。
public struct BattleSnapshot: Sendable {
    public let turn: Int
    public let player: Entity
    public let enemy: Entity
    public let energy: Int
    
    public init(turn: Int, player: Entity, enemy: Entity, energy: Int) {
        self.turn = turn
        self.player = player
        self.enemy = enemy
        self.energy = energy
    }
}

public protocol CardDefinition: Sendable {
    /// 稳定 ID（用于存档/事件/统计）
    static var id: CardID { get }
    
    /// 显示名称（当前沿用英文以减少 UI/测试波动；后续可统一中文）
    static var name: String { get }
    
    static var type: CardType { get }
    static var rarity: CardRarity { get }
    static var cost: Int { get }
    
    /// 用于 UI 展示（替代 BattleScreen 对卡牌的 switch 拼描述）
    static var rulesText: String { get }
    
    /// 升级版（升级版同样是独立 Definition）
    static var upgradedId: CardID? { get }
    
    /// 打出该卡牌后产生的效果列表
    static func play(snapshot: BattleSnapshot) -> [BattleEffect]
}

extension CardDefinition {
    public static var upgradedId: CardID? { nil }
}


