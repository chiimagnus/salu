// MARK: - Debuff Status Definitions

// ============================================================
// Vulnerable (易伤)
// ============================================================

/// 易伤：受到伤害增加 50%
public struct Vulnerable: StatusDefinition {
    public static let id: StatusID = "vulnerable"
    public static let name = "易伤"
    public static let icon = "💔"
    public static let isPositive = false
    public static let decay: StatusDecay = .turnEnd(decreaseBy: 1)
    
    public static let incomingDamagePhase: ModifierPhase? = .multiply
    public static let priority = 100
    
    public static func modifyIncomingDamage(_ value: Int, stacks: Int) -> Int {
        // 易伤：受到伤害 +50%（向下取整）
        return Int(Double(value) * 1.5)
    }
}

// ============================================================
// Weak (虚弱)
// ============================================================

/// 虚弱：造成伤害减少 25%
public struct Weak: StatusDefinition {
    public static let id: StatusID = "weak"
    public static let name = "虚弱"
    public static let icon = "😵"
    public static let isPositive = false
    public static let decay: StatusDecay = .turnEnd(decreaseBy: 1)
    
    public static let outgoingDamagePhase: ModifierPhase? = .multiply
    public static let priority = 100
    
    public static func modifyOutgoingDamage(_ value: Int, stacks: Int) -> Int {
        // 虚弱：造成伤害 -25%（向下取整）
        return Int(Double(value) * 0.75)
    }
}

// ============================================================
// Frail (脆弱)
// ============================================================

/// 脆弱：获得格挡减少 25%
public struct Frail: StatusDefinition {
    public static let id: StatusID = "frail"
    public static let name = "脆弱"
    public static let icon = "🥀"
    public static let isPositive = false
    public static let decay: StatusDecay = .turnEnd(decreaseBy: 1)
    
    public static let blockPhase: ModifierPhase? = .multiply
    public static let priority = 100
    
    public static func modifyBlock(_ value: Int, stacks: Int) -> Int {
        // 脆弱：获得格挡 -25%（向下取整）
        return Int(Double(value) * 0.75)
    }
}

// ============================================================
// Poison (中毒)
// ============================================================

/// 中毒：回合结束时造成伤害，然后递减
public struct Poison: StatusDefinition {
    public static let id: StatusID = "poison"
    public static let name = "中毒"
    public static let icon = "☠️"
    public static let isPositive = false
    public static let decay: StatusDecay = .turnEnd(decreaseBy: 1)
    
    public static func onTurnEnd(owner: EffectTarget, stacks: Int, snapshot: BattleSnapshot) -> [BattleEffect] {
        // 中毒：回合结束时造成等同于层数的伤害
        return [.dealDamage(source: owner, target: owner, base: stacks)]
    }
}
