// MARK: - Buff Status Definitions

// ============================================================
// Strength (力量)
// ============================================================

/// 力量：攻击伤害增加（永久效果）
public struct Strength: StatusDefinition {
    public static let id: StatusID = "strength"
    public static let name = "力量"
    public static let icon = "💪"
    public static let isPositive = true
    public static let decay: StatusDecay = .none  // 力量不递减
    
    public static let outgoingDamagePhase: ModifierPhase? = .add
    public static let priority = 0  // 优先级最高，最先应用
    
    public static func modifyOutgoingDamage(_ value: Int, stacks: Int) -> Int {
        // 力量：攻击伤害 +N
        return value + stacks
    }
}

// ============================================================
// Dexterity (敏捷)
// ============================================================

/// 敏捷：获得格挡增加（永久效果）
public struct Dexterity: StatusDefinition {
    public static let id: StatusID = "dexterity"
    public static let name = "敏捷"
    public static let icon = "⚡"
    public static let isPositive = true
    public static let decay: StatusDecay = .none  // 敏捷不递减
    
    public static let blockPhase: ModifierPhase? = .add
    public static let priority = 0  // 优先级最高，最先应用
    
    public static func modifyBlock(_ value: Int, stacks: Int) -> Int {
        // 敏捷：获得格挡 +N
        return value + stacks
    }
}
