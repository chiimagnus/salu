// MARK: - Buff Status Definitions

// ============================================================
// Strength (力量)
// ============================================================

/// 力量：攻击伤害增加（永久效果）
public struct Strength: StatusDefinition {
    public static let id: StatusID = "strength"
    public static let name = LocalizedText("力量", "Strength")
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
    public static let name = LocalizedText("敏捷", "Dexterity")
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

// ============================================================
// Sequence Resonance (序列共鸣) - 由能力牌产生的持续效果
// ============================================================

/// 序列共鸣（能力效果）：本场战斗中，每次预知后获得格挡
///
/// 说明：
/// - `序列共鸣（sequence_resonance）` 本身是一张能力牌（见 `Cards/Definitions/Seer/SeerCards.swift`）。
/// - 该状态用于承载“能力牌已生效”的持续效果展示与数值叠加：
///   - stacks 表示“每次预知获得的基础格挡值”（1 或 2）。
/// - 该状态不直接修正伤害/格挡，而是由 `BattleEngine.applyForesight()` 在预知结算后触发。
public struct SequenceResonanceEffect: StatusDefinition {
    public static let id: StatusID = "sequence_resonance_effect"
    public static let name = LocalizedText("序列共鸣", "Sequence Resonance")
    public static let icon = "〰️"
    public static let isPositive = true
    public static let decay: StatusDecay = .none
}
