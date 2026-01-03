// MARK: - Status Definition Framework

/// 修正阶段（决定应用顺序）
public enum ModifierPhase: Int, Sendable {
    case add = 0        // 先加（如力量/敏捷）
    case multiply = 1   // 再乘（如虚弱/易伤/脆弱）
}

/// 状态递减规则
public enum StatusDecay: Sendable, Equatable {
    case none                           // 不递减（如力量）
    case turnEnd(decreaseBy: Int)      // 回合结束递减
}

/// 状态定义协议
/// 约束：定义只产出修正或效果，不直接改状态、不直接 emit 事件
public protocol StatusDefinition: Sendable {
    /// 状态 ID
    static var id: StatusID { get }
    
    /// 显示名称（用于 UI）
    static var name: String { get }
    
    /// 图标（用于 UI）
    static var icon: String { get }
    
    /// 是否为正面效果
    static var isPositive: Bool { get }
    
    /// 递减规则（用来替代 Entity.tickStatusEffects）
    static var decay: StatusDecay { get }
    
    // ── 修正型（默认不修正） ───────────────────────────────
    
    /// 输出伤害修正阶段（nil = 不参与）
    static var outgoingDamagePhase: ModifierPhase? { get }
    
    /// 输入伤害修正阶段（nil = 不参与）
    static var incomingDamagePhase: ModifierPhase? { get }
    
    /// 格挡修正阶段（nil = 不参与）
    static var blockPhase: ModifierPhase? { get }
    
    /// 优先级（保证确定性顺序，数字越小越先应用）
    static var priority: Int { get }
    
    /// 修正输出伤害
    static func modifyOutgoingDamage(_ value: Int, stacks: Int) -> Int
    
    /// 修正输入伤害
    static func modifyIncomingDamage(_ value: Int, stacks: Int) -> Int
    
    /// 修正格挡
    static func modifyBlock(_ value: Int, stacks: Int) -> Int
    
    // ── 触发型：产出 BattleEffect（不直接 emit 事件） ───────
    
    /// 回合结束时触发（如中毒造成伤害）
    static func onTurnEnd(owner: EffectTarget, stacks: Int, snapshot: BattleSnapshot) -> [BattleEffect]
}

// MARK: - Default Implementations

extension StatusDefinition {
    public static var outgoingDamagePhase: ModifierPhase? { nil }
    public static var incomingDamagePhase: ModifierPhase? { nil }
    public static var blockPhase: ModifierPhase? { nil }
    public static var priority: Int { 0 }
    
    public static func modifyOutgoingDamage(_ value: Int, stacks: Int) -> Int { value }
    public static func modifyIncomingDamage(_ value: Int, stacks: Int) -> Int { value }
    public static func modifyBlock(_ value: Int, stacks: Int) -> Int { value }
    
    public static func onTurnEnd(owner: EffectTarget, stacks: Int, snapshot: BattleSnapshot) -> [BattleEffect] { [] }
}
