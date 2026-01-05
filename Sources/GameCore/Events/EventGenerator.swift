/// 事件生成器（P5）
///
/// 负责：
/// - 从 EventRegistry 的候选中选择一个事件（可复现）
/// - 调用事件定义生成具体的 EventOffer（含确定性选项与效果）
public enum EventGenerator {
    /// 生成事件（内部派生 seed，保证可复现）
    public static func generate(context: EventContext) -> EventOffer {
        var rng = SeededRNG(seed: deriveEventSeed(context: context))
        return generate(context: context, rng: &rng)
    }
    
    /// 生成事件（使用外部 rng）
    public static func generate(context: EventContext, rng: inout SeededRNG) -> EventOffer {
        let pool = EventRegistry.allEventIds
        precondition(!pool.isEmpty, "EventRegistry 不能为空")
        
        let picked = rng.shuffled(pool).first ?? pool[0]
        let def = EventRegistry.require(picked)
        return def.generate(context: context, rng: &rng)
    }
    
    private static func deriveEventSeed(context: EventContext) -> UInt64 {
        // 设计目标：
        // - 同 seed + 同 row + 同 node → 事件稳定
        // - 与奖励/商店/遗物使用不同 salt，避免强相关
        var s = context.seed
        s ^= UInt64(context.floor) &* 0xA24BAED4963EE407
        s ^= UInt64(context.currentRow) &* 0x9FB21C651E98DF25
        s ^= fnv1a64(context.nodeId)
        s ^= 0xE7E7_E7E7_0000_0000
        return s
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


