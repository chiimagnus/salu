// MARK: - Relic Definition Protocol

/// 遗物稀有度
public enum RelicRarity: String, Sendable {
    case starter = "起始"
    case common = "普通"
    case uncommon = "罕见"
    case rare = "稀有"
    case boss = "Boss"
    case event = "事件"
}

/// 遗物定义协议（Hook）
/// 约束：只能产出 [BattleEffect]，不直接修改 BattleState，也不直接 emit 事件
public protocol RelicDefinition: Sendable {
    /// 遗物 ID
    static var id: RelicID { get }
    
    /// 显示名称（用于 UI）
    static var name: String { get }
    
    /// 描述文本
    static var description: String { get }
    
    /// 稀有度
    static var rarity: RelicRarity { get }
    
    /// 图标
    static var icon: String { get }
    
    /// 触发：由 BattleEngine 在对应时机调用
    /// - Parameters:
    ///   - trigger: 触发点
    ///   - snapshot: 战斗快照
    /// - Returns: 产出的战斗效果列表
    static func onBattleTrigger(_ trigger: BattleTrigger, snapshot: BattleSnapshot) -> [BattleEffect]
}
