// MARK: - Relic Registry

/// 遗物注册表
/// 新增遗物的唯一扩展点
public enum RelicRegistry {
    /// 注册的遗物定义
    private static let defs: [RelicID: any RelicDefinition.Type] = [
        // Starter Relics
        BurningBloodRelic.id: BurningBloodRelic.self,
        
        // Common Relics
        VajraRelic.id: VajraRelic.self,
        LanternRelic.id: LanternRelic.self,
        IronBracerRelic.id: IronBracerRelic.self,
        
        // Uncommon Relics
        FeatherCloakRelic.id: FeatherCloakRelic.self,
        
        // Rare Relics
        WarBannerRelic.id: WarBannerRelic.self,
        
        // Boss Relics
        ColossusCoreRelic.id: ColossusCoreRelic.self,
    ]
    
    /// 获取遗物定义
    public static func get(_ id: RelicID) -> (any RelicDefinition.Type)? {
        return defs[id]
    }
    
    /// 强制获取遗物定义（找不到会崩溃，用于必须存在的遗物）
    public static func require(_ id: RelicID) -> any RelicDefinition.Type {
        precondition(defs[id] != nil, "RelicRegistry: 未找到遗物定义 '\(id.rawValue)'")
        return defs[id]!
    }
    
    /// 获取所有已注册的遗物 ID
    public static var allRelicIds: [RelicID] {
        return Array(defs.keys).sorted { $0.rawValue < $1.rawValue }
    }
}
