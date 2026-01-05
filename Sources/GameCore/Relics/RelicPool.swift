/// 遗物掉落池
/// - 负责筛选可掉落的遗物（排除起始/已拥有）
public enum RelicPool {
    /// 可掉落的遗物 ID 列表（排除起始稀有度 + 已拥有）
    public static func availableRelicIds(excluding ownedRelics: [RelicID]) -> [RelicID] {
        RelicRegistry.allRelicIds.filter { relicId in
            let def = RelicRegistry.require(relicId)
            return def.rarity != .starter && !ownedRelics.contains(relicId)
        }
    }
    
    /// 根据稀有度筛选可掉落遗物
    public static func relicIds(
        rarity: RelicRarity,
        excluding ownedRelics: [RelicID]
    ) -> [RelicID] {
        RelicRegistry.allRelicIds.filter { relicId in
            let def = RelicRegistry.require(relicId)
            return def.rarity == rarity && !ownedRelics.contains(relicId)
        }
    }
}
