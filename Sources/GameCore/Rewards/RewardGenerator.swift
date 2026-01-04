/// 奖励生成器（P1：战斗后卡牌奖励）
public enum RewardGenerator {
    /// 生成卡牌奖励（内部派生 seed，保证可复现）
    public static func generateCardReward(context: RewardContext) -> CardRewardOffer {
        var rng = SeededRNG(seed: deriveRewardSeed(context: context))
        return generateCardReward(context: context, rng: &rng)
    }
    
    /// 生成卡牌奖励（使用外部 rng，方便未来扩展组合奖励）
    public static func generateCardReward(context: RewardContext, rng: inout SeededRNG) -> CardRewardOffer {
        let pool = CardPool.rewardableCardIds()
        
        guard !pool.isEmpty else {
            return CardRewardOffer(choices: [], canSkip: true)
        }
        
        // 洗牌后取前 3 个，保证去重
        let shuffled = rng.shuffled(pool)
        let choices = Array(shuffled.prefix(3))
        return CardRewardOffer(choices: choices, canSkip: true)
    }
    
    private static func deriveRewardSeed(context: RewardContext) -> UInt64 {
        // 设计目标：
        // - 同 seed + 同 row + 同 node + 同 roomType → 结果稳定
        // - 不引入 run-level RNG state（P1 先用派生 seed）
        var s = context.seed
        s ^= UInt64(context.floor) &* 0x9E3779B97F4A7C15
        s ^= UInt64(context.currentRow) &* 0xBF58476D1CE4E5B9
        s ^= fnv1a64(context.nodeId)
        s ^= roomTypeSalt(context.roomType)
        return s
    }
    
    private static func roomTypeSalt(_ roomType: RoomType) -> UInt64 {
        switch roomType {
        case .battle:
            return 0xB4A7_7E00_0000_0000
        case .elite:
            return 0xE11E_7E00_0000_0000
        default:
            // P1 只用于 battle/elite；其他类型保持稳定即可
            return 0xA11C_E000_0000_0000
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


