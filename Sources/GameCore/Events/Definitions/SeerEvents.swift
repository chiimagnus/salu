// MARK: - Seer Sequence Events (占卜家序列事件)

// ============================================================
// Seer Sequence Chamber (序列密室)
// ============================================================

/// 序列密室
public struct SeerSequenceChamberEvent: EventDefinition {
    public static let id: EventID = "seer_sequence_chamber"
    public static let name = "序列密室"
    public static let icon = "📚"
    public static let description = """
你在走廊尽头发现一扇隐秘的门。推开后，一间布满灰尘的密室呈现在眼前——书架上堆满了古老的典籍，空气中弥漫着墨水和腐朽的气息。

一本封面刻着奇异符号的书正摊开在桌上，仿佛在等待阅读者。
"""
    
    public static func generate(context: EventContext, rng: inout SeededRNG) -> EventOffer {
        _ = context
        _ = rng
        
        let options: [EventOption] = [
            EventOption(
                title: "阅读禁书",
                preview: "获得卡牌：命运改写；疯狂 +3",
                effects: [
                    .addCard(cardId: "fate_rewrite"),
                    .applyStatus(statusId: "madness", stacks: 3),
                ]
            ),
            EventOption(
                title: "焚毁书页",
                preview: "恢复理智：疯狂 -3；代价：失去 10 HP",
                effects: [
                    .applyStatus(statusId: "madness", stacks: -3),
                    .takeDamage(amount: 10),
                ]
            ),
            EventOption(
                title: "转身离开",
                preview: "无事发生",
                effects: []
            ),
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
// Seer Time Rift (时间裂隙)
// ============================================================

/// 时间裂隙
public struct SeerTimeRiftEvent: EventDefinition {
    public static let id: EventID = "seer_time_rift"
    public static let name = "时间裂隙"
    public static let icon = "⏳"
    public static let description = """
空气中出现一道微妙的裂痕，仿佛现实在这里破碎。

透过裂隙，你能隐约看到两个方向——一边是模糊的过去，另一边是朦胧的未来。

选择一个方向窥视，还是闭上眼睛离开？
"""
    
    public static func generate(context: EventContext, rng: inout SeededRNG) -> EventOffer {
        _ = rng
        
        let upgradeable = RunState.upgradeableCardIndices(in: context.deck)
        
        var options: [EventOption] = []
        
        // 窥视过去：升级（若可升级卡为空，则该选项变为“离开”）
        if upgradeable.isEmpty {
            options.append(EventOption(
                title: "窥视过去",
                preview: "你什么也没看见（没有可升级的卡牌）",
                effects: []
            ))
        } else {
            options.append(EventOption(
                title: "窥视过去",
                preview: "升级 1 张卡牌；疯狂 +2",
                effects: [
                    .applyStatus(statusId: "madness", stacks: 2),
                ],
                followUp: .chooseUpgradeableCard(indices: upgradeable)
            ))
        }
        
        // 窥视未来：破碎怀表 + 疯狂
        options.append(EventOption(
            title: "窥视未来",
            preview: "获得遗物：破碎怀表；疯狂 +2",
            effects: [
                .addRelic(relicId: "broken_watch"),
                .applyStatus(statusId: "madness", stacks: 2),
            ]
        ))
        
        // 闭眼离开：回血
        options.append(EventOption(
            title: "闭眼离开",
            preview: "回复 10 HP",
            effects: [
                .heal(amount: 10),
            ]
        ))
        
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
// Mad Prophet (疯狂预言者)
// ============================================================

/// 疯狂预言者
///
/// 说明：
/// - 事件本身只产出“可复现的选择数据”
/// - “进入战斗”的实际流程与奖励由 CLI（EventRoomHandler）执行
public struct SeerMadProphetEvent: EventDefinition {
    public static let id: EventID = "seer_mad_prophet"
    public static let name = "疯狂预言者"
    public static let icon = "🔮"
    public static let description = """
一个衣衫褴褛的老人蹲在路边，双眼蒙着布条，嘴里喃喃自语。

当你靠近时，他突然抬起头，布条下的眼眶空洞无物——但你感觉他正在“看”着你。

「我知道你的命运，」他沙哑地说，「想听听吗？」
"""
    
    public static func generate(context: EventContext, rng: inout SeededRNG) -> EventOffer {
        _ = context
        _ = rng
        
        let options: [EventOption] = [
            EventOption(
                title: "聆听预言",
                preview: "获得卡牌：深渊凝视；疯狂 +4",
                effects: [
                    .addCard(cardId: "abyssal_gaze"),
                    .applyStatus(statusId: "madness", stacks: 4),
                ]
            ),
            EventOption(
                title: "打断他",
                preview: "进入战斗：疯狂预言者（精英）",
                effects: [],
                followUp: .startEliteBattle(enemyId: "mad_prophet")
            ),
            EventOption(
                title: "给予金币安抚",
                preview: "失去 30 金币；回复 15 HP；疯狂 -2",
                effects: [
                    .loseGold(amount: 30),
                    .heal(amount: 15),
                    .applyStatus(statusId: "madness", stacks: -2),
                ]
            ),
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
