/// 遗物掉落来源
public enum RelicDropSource: String, Sendable {
    case elite
    case boss
}

/// 遗物掉落策略
public enum RelicDropStrategy {
    /// 生成遗物掉落（内部派生 seed，保证可复现）
    public static func generateRelicDrop(
        context: RewardContext,
        source: RelicDropSource,
        ownedRelics: [RelicID]
    ) -> RelicID? {
        var rng = SeededRNG(seed: deriveRelicSeed(context: context, source: source))
        return generateRelicDrop(context: context, source: source, ownedRelics: ownedRelics, rng: &rng)
    }
    
    /// 生成遗物掉落（使用外部 rng）
    public static func generateRelicDrop(
        context: RewardContext,
        source: RelicDropSource,
        ownedRelics: [RelicID],
        rng: inout SeededRNG
    ) -> RelicID? {
        let pool = dropCandidates(source: source, ownedRelics: ownedRelics)
        guard !pool.isEmpty else { return nil }
        
        let shuffled = rng.shuffled(pool)
        return shuffled.first
    }
    
    private static func dropCandidates(source: RelicDropSource, ownedRelics: [RelicID]) -> [RelicID] {
        let preferredRarities: [RelicRarity]
        switch source {
        case .elite:
            preferredRarities = [.common, .uncommon, .rare]
        case .boss:
            preferredRarities = [.boss, .rare, .uncommon, .common]
        }
        
        var pool: [RelicID] = []
        for rarity in preferredRarities {
            pool.append(contentsOf: RelicPool.relicIds(rarity: rarity, excluding: ownedRelics))
        }
        
        if pool.isEmpty {
            pool = RelicPool.availableRelicIds(excluding: ownedRelics)
        }
        
        return pool
    }
    
    private static func deriveRelicSeed(context: RewardContext, source: RelicDropSource) -> UInt64 {
        var s = context.seed
        s ^= UInt64(context.floor) &* 0xD6E8FEB86659FD93
        s ^= UInt64(context.currentRow) &* 0x94D049BB133111EB
        s ^= fnv1a64(context.nodeId)
        s ^= roomTypeSalt(context.roomType)
        s ^= sourceSalt(source)
        return s
    }
    
    private static func roomTypeSalt(_ roomType: RoomType) -> UInt64 {
        switch roomType {
        case .elite:
            return 0xE11E_7E11_0000_0000
        case .boss:
            return 0xB055_0000_0000_0000
        default:
            return 0xA11C_EE11_0000_0000
        }
    }
    
    private static func sourceSalt(_ source: RelicDropSource) -> UInt64 {
        switch source {
        case .elite:
            return 0xE1E7_EE11_0000_0000
        case .boss:
            return 0xB055_B055_0000_0000
        }
    }
    
    /// FNV-1a 64-bit hash（纯 Swift，无 Foundation）
    private static func fnv1a64(_ string: String) -> UInt64 {
        let bytes = Array(string.utf8)
        var hash: UInt64 = 0xcbf29ce484222325
        for b in bytes {
            hash ^= UInt64(b)
            hash &*= 0x100000001b3
        }
        return hash
    }
}
