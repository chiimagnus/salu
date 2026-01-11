// MARK: - Consumable Definition Protocol

/// 消耗品 ID
public struct ConsumableID: Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}

/// 消耗品稀有度
public enum ConsumableRarity: String, Sendable {
    case common = "普通"
    case uncommon = "罕见"
    case rare = "稀有"
}

/// 消耗品定义协议
/// 消耗品是一次性使用的道具，可在战斗外或战斗中使用
public protocol ConsumableDefinition: Sendable {
    /// 消耗品 ID
    static var id: ConsumableID { get }
    
    /// 显示名称
    static var name: String { get }
    
    /// 描述文本
    static var description: String { get }
    
    /// 稀有度
    static var rarity: ConsumableRarity { get }
    
    /// 图标
    static var icon: String { get }
    
    /// 是否可在战斗中使用
    static var usableInBattle: Bool { get }
    
    /// 是否可在战斗外使用
    static var usableOutsideBattle: Bool { get }
    
    /// 战斗中使用效果
    /// - Parameter snapshot: 当前战斗快照
    /// - Returns: 战斗效果列表
    static func useInBattle(snapshot: BattleSnapshot) -> [BattleEffect]
    
    /// 战斗外使用效果
    /// - Returns: 冒险效果列表
    static func useOutsideBattle() -> [RunEffect]
}

// MARK: - Default Implementations

public extension ConsumableDefinition {
    static var usableInBattle: Bool { true }
    static var usableOutsideBattle: Bool { false }
    
    static func useInBattle(snapshot: BattleSnapshot) -> [BattleEffect] { [] }
    static func useOutsideBattle() -> [RunEffect] { [] }
}
