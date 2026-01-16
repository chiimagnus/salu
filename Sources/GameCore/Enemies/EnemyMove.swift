// MARK: - Enemy Move System

/// 敌人意图（仅用于 UI 显示）
/// 注意：意图不是执行逻辑，执行逻辑靠 effects
public struct EnemyIntentDisplay: Sendable, Equatable {
    public let icon: String
    public let text: LocalizedText
    public let previewDamage: Int?
    
    public init(icon: String, text: LocalizedText, previewDamage: Int? = nil) {
        self.icon = icon
        self.text = text
        self.previewDamage = previewDamage
    }
}

/// 敌人计划行动（一次"计划"，包含 intent + effects）
/// 约束：定义只产出 Move，不直接执行或发事件
public struct EnemyMove: Sendable, Equatable {
    public let intent: EnemyIntentDisplay
    public let effects: [BattleEffect]
    
    public init(intent: EnemyIntentDisplay, effects: [BattleEffect]) {
        self.intent = intent
        self.effects = effects
    }
}
