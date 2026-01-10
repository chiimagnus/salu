// MARK: - Basic Event Definitions (P5/P2)
//
// v0.1 叙事风格：克苏鲁/诡秘之主 + 碎片叙事
// 每个事件都应该：
// - 有符合世界观的名称和描述
// - 通过对话/描述透露世界观碎片
// - 选项文案体现角色决策

// ============================================================
// Wanderer's Whisper（流浪者的低语）
// 原：拾荒者 → 改造为遇到前任终结者的幽灵
// ============================================================

/// 流浪者的低语：给金币 / 以 HP 换更多金币（深入对话）/ 离开
public struct ScavengerEvent: EventDefinition {
    public static let id: EventID = "scavenger"
    public static let name = "流浪者的低语"
    public static let icon = "👻"
    public static let description = """
    一个身影从阴影中浮现，身形模糊得像是被雾气笼罩。
    
    "又一个被选中的人……"它的声音如同风中的低语，"上一个和你一样，充满希望地踏上旅途。"
    
    它的手中似乎握着什么东西。
    """
    
    public static func generate(context: EventContext, rng: inout SeededRNG) -> EventOffer {
        let smallGold = 30 + rng.nextInt(upperBound: 21)     // 30~50
        let bigGold = 70 + rng.nextInt(upperBound: 21)       // 70~90
        let damage = 6 + rng.nextInt(upperBound: 5)          // 6~10
        
        let options: [EventOption] = [
            EventOption(
                title: "接过他手中的东西",
                preview: "获得 \(smallGold) 金币",
                effects: [.gainGold(amount: smallGold)]
            ),
            EventOption(
                title: "询问他的故事",
                preview: "失去 \(damage) HP（精神冲击），获得 \(bigGold) 金币",
                effects: [.takeDamage(amount: damage), .gainGold(amount: bigGold)]
            ),
            EventOption(
                title: "转身离开",
                preview: nil,
                effects: []
            )
        ]
        
        return EventOffer(
            eventId: id,
            name: name,
            icon: icon,
            description: description,
            options: options
        )
    }
}

// ============================================================
// Sequence Altar（序列祭坛）
// 原：祭坛 → 改造为序列符文祭坛
// ============================================================

/// 序列祭坛：献祭金币换遗物 / 祈祷回血 / 离开
public struct AltarEvent: EventDefinition {
    public static let id: EventID = "altar"
    public static let name = "序列祭坛"
    public static let icon = "🗿"
    public static let description = """
    一座古老的祭坛矗立在道路中央，表面刻满了扭曲的序列符文。
    
    符文散发着幽暗的光芒，似乎在等待某种献祭。祭坛底部的铭文已经模糊不清，只能辨认出几个字：
    
    "……以血肉为锁，以灵魂为钥……"
    """
    
    public static func generate(context: EventContext, rng: inout SeededRNG) -> EventOffer {
        let sacrificeGold = 50
        let healAmount = 10
        
        var options: [EventOption] = []
        
        // 1) 献祭金币换遗物：需要金币足够且存在可用遗物
        if context.gold >= sacrificeGold {
            let candidates = RelicPool.availableRelicIds(excluding: context.relicIds)
            if let picked = rng.shuffled(candidates).first {
                options.append(
                    EventOption(
                        title: "献上供奉（\(sacrificeGold) 金币）",
                        preview: "获得遗物：\(RelicRegistry.require(picked).name)",
                        effects: [.loseGold(amount: sacrificeGold), .addRelic(relicId: picked)]
                    )
                )
            }
        }
        
        // 2) 祈祷回血：始终提供（不超过最大生命）
        options.append(
            EventOption(
                title: "触碰符文祈祷",
                preview: "恢复 \(healAmount) HP",
                effects: [.heal(amount: healAmount)]
            )
        )
        
        // 3) 离开
        options.append(
            EventOption(
                title: "保持距离，离开",
                preview: nil,
                effects: []
            )
        )
        
        return EventOffer(
            eventId: id,
            name: name,
            icon: icon,
            description: description,
            options: options
        )
    }
}

// ============================================================
// Nikola's Guidance（尼古拉的指导）
// 原：训练 → 改造为 NPC 尼古拉出现，提供战斗指导
// ============================================================

/// 尼古拉的指导：升级一张可升级卡 / 学习新招（获得一张卡）/ 离开
public struct TrainingEvent: EventDefinition {
    public static let id: EventID = "training"
    public static let name = "尼古拉的指导"
    public static let icon = "🤝"
    public static let description = """
    "嘿，朋友！"一个爽朗的声音从背后传来。
    
    是尼古拉。他拍了拍你的肩膀，露出标志性的笑容：
    
    "看你的样子，最近经历了不少战斗吧？来，让我教你几招。相信我，在这个世界活下去，需要的不只是勇气。"
    """
    
    public static func generate(context: EventContext, rng: inout SeededRNG) -> EventOffer {
        var options: [EventOption] = []
        
        // 1) 升级：若存在可升级卡，则让玩家选择要升级的卡牌（P5：二次选择）
        let upgradeable = RunState.upgradeableCardIndices(in: context.deck)
        if !upgradeable.isEmpty {
            options.append(
                EventOption(
                    title: "接受尼古拉的指导",
                    preview: "升级 1 张可升级卡牌",
                    effects: [],
                    followUp: .chooseUpgradeableCard(indices: upgradeable)
                )
            )
        }
        
        // 2) 学习新招：从可奖励卡池中选一张（确定性）
        let pool = CardPool.rewardableCardIds()
        if let picked = rng.shuffled(pool).first {
            let def = CardRegistry.require(picked)
            options.append(
                EventOption(
                    title: "请尼古拉传授新招",
                    preview: "获得：\(def.name)",
                    effects: [.addCard(cardId: picked)]
                )
            )
        }
        
        // 3) 离开
        options.append(
            EventOption(
                title: "谢绝好意，继续前进",
                preview: nil,
                effects: []
            )
        )
        
        return EventOffer(
            eventId: id,
            name: name,
            icon: icon,
            description: description,
            options: options
        )
    }
}
