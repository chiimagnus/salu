// MARK: - Card Registry

/// 卡牌注册表
/// 新增卡牌的唯一扩展点
public enum CardRegistry {
    /// 注册的卡牌定义
    private static let defs: [CardID: any CardDefinition.Type] = [
        // Basic Cards
        Strike.id: Strike.self,
        StrikePlus.id: StrikePlus.self,
        Defend.id: Defend.self,
        DefendPlus.id: DefendPlus.self,
        Bash.id: Bash.self,
        BashPlus.id: BashPlus.self,
        
        // Common Cards
        PommelStrike.id: PommelStrike.self,
        ShrugItOff.id: ShrugItOff.self,
        Inflame.id: Inflame.self,
        Clothesline.id: Clothesline.self,
        
        // Act 1 Expansion Cards (P7)
        Cleave.id: Cleave.self,
        Intimidate.id: Intimidate.self,
        AgileStance.id: AgileStance.self,
        PoisonedStrike.id: PoisonedStrike.self,
        
        // Seer Sequence Cards - Common (P1 占卜家序列普通卡)
        SpiritSight.id: SpiritSight.self,
        SpiritSightPlus.id: SpiritSightPlus.self,
        TruthWhisper.id: TruthWhisper.self,
        TruthWhisperPlus.id: TruthWhisperPlus.self,
        Meditation.id: Meditation.self,
        MeditationPlus.id: MeditationPlus.self,
        SanityBurn.id: SanityBurn.self,
        SanityBurnPlus.id: SanityBurnPlus.self,
        
        // Seer Sequence Cards - Uncommon (P1 占卜家序列罕见卡)
        FateRewrite.id: FateRewrite.self,
        FateRewritePlus.id: FateRewritePlus.self,
        TimeShard.id: TimeShard.self,
        TimeShardPlus.id: TimeShardPlus.self,
    ]
    
    /// 获取卡牌定义
    public static func get(_ id: CardID) -> (any CardDefinition.Type)? {
        return defs[id]
    }
    
    /// 强制获取卡牌定义（找不到会崩溃，用于必须存在的卡牌）
    public static func require(_ id: CardID) -> any CardDefinition.Type {
        precondition(defs[id] != nil, "CardRegistry: 未找到卡牌定义 '\(id.rawValue)'")
        return defs[id]!
    }

    /// 获取所有已注册的卡牌 ID（按 rawValue 排序，保证确定性）
    public static var allCardIds: [CardID] {
        Array(defs.keys).sorted { $0.rawValue < $1.rawValue }
    }
}
