// MARK: - Basic Event Definitions (P5)

// ============================================================
// Scavenger（拾荒者）
// ============================================================

/// 拾荒者：给金币 / 以 HP 换更多金币 / 离开
public struct ScavengerEvent: EventDefinition {
    public static let id: EventID = "scavenger"
    public static let name = "拾荒者"
    public static let icon = "🪙"
    public static let description = "你在角落发现了一只破旧的袋子，里面似乎装着什么。"
    
    public static func generate(context: EventContext, rng: inout SeededRNG) -> EventOffer {
        let smallGold = 30 + rng.nextInt(upperBound: 21)     // 30~50
        let bigGold = 70 + rng.nextInt(upperBound: 21)       // 70~90
        let damage = 6 + rng.nextInt(upperBound: 5)          // 6~10
        
        let options: [EventOption] = [
            EventOption(
                title: "拿走金币",
                preview: "获得 \(smallGold) 金币",
                effects: [.gainGold(amount: smallGold)]
            ),
            EventOption(
                title: "翻找更深处",
                preview: "失去 \(damage) HP，获得 \(bigGold) 金币",
                effects: [.takeDamage(amount: damage), .gainGold(amount: bigGold)]
            ),
            EventOption(
                title: "离开",
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
// Altar（祭坛）
// ============================================================

/// 祭坛：献祭金币换遗物 / 祈祷回血 / 离开
public struct AltarEvent: EventDefinition {
    public static let id: EventID = "altar"
    public static let name = "祭坛"
    public static let icon = "🗿"
    public static let description = "一座古老的祭坛矗立在路边，散发着令人不安的气息。"
    
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
                        title: "献祭 \(sacrificeGold) 金币",
                        preview: "获得遗物：\(RelicRegistry.require(picked).name)",
                        effects: [.loseGold(amount: sacrificeGold), .addRelic(relicId: picked)]
                    )
                )
            }
        }
        
        // 2) 祈祷回血：始终提供（不超过最大生命）
        options.append(
            EventOption(
                title: "祈祷",
                preview: "恢复 \(healAmount) HP",
                effects: [.heal(amount: healAmount)]
            )
        )
        
        // 3) 离开
        options.append(
            EventOption(
                title: "离开",
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
// Training（训练）
// ============================================================

/// 训练：升级一张可升级卡 / 学习新招（获得一张卡）/ 离开
public struct TrainingEvent: EventDefinition {
    public static let id: EventID = "training"
    public static let name = "训练"
    public static let icon = "🥊"
    public static let description = "你找到了一处空地，可以进行短暂训练。"
    
    public static func generate(context: EventContext, rng: inout SeededRNG) -> EventOffer {
        var options: [EventOption] = []
        
        // 1) 升级：若存在可升级卡，则让玩家选择要升级的卡牌（P5：二次选择）
        let upgradeable = RunState.upgradeableCardIndices(in: context.deck)
        if !upgradeable.isEmpty {
            options.append(
                EventOption(
                    title: "专注训练",
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
                    title: "学习新招",
                    preview: "获得：\(def.name)",
                    effects: [.addCard(cardId: picked)]
                )
            )
        }
        
        // 3) 离开
        options.append(
            EventOption(
                title: "离开",
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


