// MARK: - Consumable Registry

/// 消耗品注册表
/// 新增消耗品的唯一扩展点
public enum ConsumableRegistry {
    /// 注册的消耗品定义
    private static let defs: [ConsumableID: any ConsumableDefinition.Type] = [
        // Seer Sequence Consumables
        PurificationRuneConsumable.id: PurificationRuneConsumable.self,
        
        // Common Consumables
        HealingPotionConsumable.id: HealingPotionConsumable.self,
        BlockPotionConsumable.id: BlockPotionConsumable.self,
        StrengthPotionConsumable.id: StrengthPotionConsumable.self,
    ]
    
    /// 获取消耗品定义
    public static func get(_ id: ConsumableID) -> (any ConsumableDefinition.Type)? {
        return defs[id]
    }
    
    /// 强制获取消耗品定义
    public static func require(_ id: ConsumableID) -> any ConsumableDefinition.Type {
        precondition(defs[id] != nil, "ConsumableRegistry: 未找到消耗品定义 '\(id.rawValue)'")
        return defs[id]!
    }
    
    /// 获取所有已注册的消耗品 ID
    public static var allConsumableIds: [ConsumableID] {
        return Array(defs.keys).sorted { $0.rawValue < $1.rawValue }
    }
    
    /// 获取可在商店购买的消耗品 ID
    public static var shopConsumableIds: [ConsumableID] {
        // 所有消耗品都可以在商店购买
        return allConsumableIds
    }
}
