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
        ThirdEyeRelic.id: ThirdEyeRelic.self,         // P3: 第三只眼
        BrokenWatchRelic.id: BrokenWatchRelic.self,   // P3: 破碎怀表
        
        // Uncommon Relics
        FeatherCloakRelic.id: FeatherCloakRelic.self,
        SanityAnchorRelic.id: SanityAnchorRelic.self, // P3: 理智之锚
        AbyssalEyeRelic.id: AbyssalEyeRelic.self,     // P3: 深渊之瞳
        ProphetNotesRelic.id: ProphetNotesRelic.self, // P3: 预言者手札
        
        // Rare Relics
        WarBannerRelic.id: WarBannerRelic.self,
        MadnessMaskRelic.id: MadnessMaskRelic.self,   // P3: 疯狂面具
        
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
