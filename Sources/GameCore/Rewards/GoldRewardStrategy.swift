/// 金币奖励策略（P2：战斗胜利给金币）
///
/// 约束：
/// - 必须可复现（同 seed + 同路径选择 → 金币奖励一致）
/// - 纯逻辑：不依赖 Foundation、不做 I/O
public enum GoldRewardStrategy {
    /// 生成金币奖励（内部派生 seed，保证可复现）
    public static func generateGoldReward(context: RewardContext) -> Int {
        var rng = SeededRNG(seed: deriveGoldSeed(context: context))
        return generateGoldReward(context: context, rng: &rng)
    }
    
    /// 生成金币奖励（使用外部 rng，方便未来组合奖励）
    public static func generateGoldReward(context: RewardContext, rng: inout SeededRNG) -> Int {
        switch context.roomType {
        case .battle:
            // 普通战斗：10~20
            return 10 + rng.nextInt(upperBound: 11)
        case .elite:
            // 精英战斗：25~35
            return 25 + rng.nextInt(upperBound: 11)
        case .boss:
            // Boss：100~110（当前主要用于未来扩展）
            return 100 + rng.nextInt(upperBound: 11)
        default:
            return 0
        }
    }
    
    private static func deriveGoldSeed(context: RewardContext) -> UInt64 {
        // 设计目标：
        // - 同 seed + 同 row + 同 node + 同 roomType → 结果稳定
        // - 与卡牌奖励（RewardGenerator）使用不同 salt，避免强相关
        var s = context.seed
        s ^= UInt64(context.floor) &* 0xC2B2AE3D27D4EB4F
        s ^= UInt64(context.currentRow) &* 0x165667B19E3779F9
        s ^= fnv1a64(context.nodeId)
        s ^= roomTypeSalt(context.roomType)
        s ^= 0x601D_C01D_0000_0000
        return s
    }
    
    private static func roomTypeSalt(_ roomType: RoomType) -> UInt64 {
        switch roomType {
        case .battle:
            return 0xB4A7_601D_0000_0000
        case .elite:
            return 0xE11E_601D_0000_0000
        case .boss:
            return 0xB055_601D_0000_0000
        default:
            return 0xA11C_601D_0000_0000
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


