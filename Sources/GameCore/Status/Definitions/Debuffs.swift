// MARK: - Debuff Status Definitions

// ============================================================
// Vulnerable (易伤)
// ============================================================

/// 易伤：受到伤害增加 50%
public struct Vulnerable: StatusDefinition {
    public static let id: StatusID = "vulnerable"
    public static let name = LocalizedText("易伤", "Vulnerable")
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
    public static let name = LocalizedText("虚弱", "Weak")
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
    public static let name = LocalizedText("脆弱", "Frail")
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
    public static let name = LocalizedText("中毒", "Poison")
    public static let icon = "☠️"
    public static let isPositive = false
    public static let decay: StatusDecay = .turnEnd(decreaseBy: 1)
    
    public static func onTurnEnd(owner: EffectTarget, stacks: Int, snapshot: BattleSnapshot) -> [BattleEffect] {
        // 中毒：回合结束时造成等同于层数的伤害
        return [.dealDamage(source: owner, target: owner, base: stacks)]
    }
}

// ============================================================
// Madness (疯狂) - 占卜家序列核心状态
// ============================================================

/// 疯狂：占卜家使用强力能力的代价
///
/// **阈值效果**（在回合开始时检查）：
/// - 阈值 1（≥3 层）：随机弃 1 张手牌
/// - 阈值 2（≥6 层）：获得虚弱 1
/// - 阈值 3（≥10 层）：受到伤害 +50%（类似易伤）
///
/// **消减规则**：
/// - 回合结束时 -1（由 BattleEngine 专门处理，不使用 decay）
///
/// **设计说明**：
/// 疯狂不使用 `StatusDecay.turnEnd` 是因为消减发生在回合结束，
/// 而阈值检查发生在回合开始；如果用 decay，递减会在回合结束时
/// 与状态触发同时发生，时机不对。
public struct Madness: StatusDefinition {
    public static let id: StatusID = "madness"
    public static let name = LocalizedText("疯狂", "Madness")
    public static let icon = "🌀"
    public static let isPositive = false
    public static let decay: StatusDecay = .none  // 由 BattleEngine 在回合结束时手动 -1
    
    // MARK: - 阈值常量
    
    /// 阈值 1：随机弃牌
    public static let threshold1 = 3
    /// 阈值 2：获得虚弱
    public static let threshold2 = 6
    /// 阈值 3：受到伤害增加
    public static let threshold3 = 10
    
    // MARK: - 阈值 3 的伤害修正
    
    /// 阈值 3（≥10 层）时参与伤害修正
    public static let incomingDamagePhase: ModifierPhase? = .multiply
    /// 在易伤之后应用（易伤 priority = 100）
    public static let priority = 200
    
    public static func modifyIncomingDamage(_ value: Int, stacks: Int) -> Int {
        // 阈值 3（≥10 层）：受到伤害 +50%
        if stacks >= threshold3 {
            return Int(Double(value) * 1.5)
        }
        return value
    }
}
