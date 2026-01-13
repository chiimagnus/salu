// MARK: - Status Registry

/// 状态注册表
/// 新增状态的唯一扩展点
public enum StatusRegistry {
    /// 注册的状态定义
    private static let defs: [StatusID: any StatusDefinition.Type] = [
        // Debuffs
        Vulnerable.id: Vulnerable.self,
        Weak.id: Weak.self,
        Frail.id: Frail.self,
        Poison.id: Poison.self,
        Madness.id: Madness.self,  // 占卜家序列核心状态
        
        // Buffs
        Strength.id: Strength.self,
        Dexterity.id: Dexterity.self,
        SequenceResonance.id: SequenceResonance.self,
    ]
    
    /// 获取状态定义
    public static func get(_ id: StatusID) -> (any StatusDefinition.Type)? {
        return defs[id]
    }
    
    /// 强制获取状态定义（找不到会崩溃，用于必须存在的状态）
    public static func require(_ id: StatusID) -> any StatusDefinition.Type {
        precondition(defs[id] != nil, "StatusRegistry: 未找到状态定义 '\(id.rawValue)'")
        return defs[id]!
    }
}
