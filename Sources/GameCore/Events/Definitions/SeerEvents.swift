// MARK: - Seer Sequence Events (占卜家序列事件)

// ============================================================
// Seer Sequence Chamber (序列密室)
// ============================================================

/// 序列密室
public struct SeerSequenceChamberEvent: EventDefinition {
    public static let id: EventID = "seer_sequence_chamber"
    public static let name = LocalizedText("序列密室", "Sequence Chamber")
    public static let icon = "📚"
    public static let description = LocalizedText(
        """
你在走廊尽头发现一扇隐秘的门。推开后，一间布满灰尘的密室呈现在眼前——书架上堆满了古老的典籍，空气中弥漫着墨水和腐朽的气息。

一本封面刻着奇异符号的书正摊开在桌上，仿佛在等待阅读者。
""",
        """
At the end of the corridor, you find a hidden door. Inside lies a dust-covered chamber—shelves packed with ancient tomes, the air thick with ink and decay.

An open book with strange symbols on its cover rests on the table, as if waiting for a reader.
"""
    )
    
    public static func generate(context: EventContext, rng: inout SeededRNG) -> EventOffer {
        _ = context
        _ = rng
        
        let fateRewrite = CardRegistry.require("fate_rewrite").name
        let options: [EventOption] = [
            EventOption(
                title: LocalizedText("阅读禁书", "Read the forbidden tome"),
                preview: LocalizedText(
                    "获得卡牌：\(fateRewrite.zhHans)；疯狂 +3",
                    "Gain card: \(fateRewrite.en); Madness +3"
                ),
                effects: [
                    .addCard(cardId: "fate_rewrite"),
                    .applyStatus(statusId: "madness", stacks: 3),
                ]
            ),
            EventOption(
                title: LocalizedText("焚毁书页", "Burn the pages"),
                preview: LocalizedText(
                    "恢复理智：疯狂 -3；代价：失去 10 HP",
                    "Regain sanity: Madness -3; cost: lose 10 HP"
                ),
                effects: [
                    .applyStatus(statusId: "madness", stacks: -3),
                    .takeDamage(amount: 10),
                ]
            ),
            EventOption(
                title: LocalizedText("转身离开", "Leave"),
                preview: LocalizedText("无事发生", "Nothing happens"),
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
    public static let name = LocalizedText("时间裂隙", "Time Rift")
    public static let icon = "⏳"
    public static let description = LocalizedText(
        """
空气中出现一道微妙的裂痕，仿佛现实在这里破碎。

透过裂隙，你能隐约看到两个方向——一边是模糊的过去，另一边是朦胧的未来。

选择一个方向窥视，还是闭上眼睛离开？
""",
        """
A subtle crack appears in the air, as if reality has fractured here.

Through the rift you can faintly see two directions—one a blurred past, the other a hazy future.

Do you peer into one, or close your eyes and leave?
"""
    )
    
    public static func generate(context: EventContext, rng: inout SeededRNG) -> EventOffer {
        _ = rng
        
        let upgradeable = RunState.upgradeableCardIndices(in: context.deck)
        
        var options: [EventOption] = []
        
        // 窥视过去：升级（若可升级卡为空，则该选项变为“离开”）
        if upgradeable.isEmpty {
            options.append(EventOption(
                title: LocalizedText("窥视过去", "Gaze into the past"),
                preview: LocalizedText(
                    "你什么也没看见（没有可升级的卡牌）",
                    "You see nothing (no upgradable cards)"
                ),
                effects: []
            ))
        } else {
            options.append(EventOption(
                title: LocalizedText("窥视过去", "Gaze into the past"),
                preview: LocalizedText("升级 1 张卡牌；疯狂 +2", "Upgrade 1 card; Madness +2"),
                effects: [
                    .applyStatus(statusId: "madness", stacks: 2),
                ],
                followUp: .chooseUpgradeableCard(indices: upgradeable)
            ))
        }
        
        // 窥视未来：破碎怀表 + 疯狂
        let brokenWatch = RelicRegistry.require("broken_watch").name
        options.append(EventOption(
            title: LocalizedText("窥视未来", "Gaze into the future"),
            preview: LocalizedText(
                "获得遗物：\(brokenWatch.zhHans)；疯狂 +2",
                "Gain relic: \(brokenWatch.en); Madness +2"
            ),
            effects: [
                .addRelic(relicId: "broken_watch"),
                .applyStatus(statusId: "madness", stacks: 2),
            ]
        ))
        
        // 闭眼离开：回血
        options.append(EventOption(
            title: LocalizedText("闭眼离开", "Close your eyes and leave"),
            preview: LocalizedText("回复 10 HP", "Restore 10 HP"),
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
    public static let name = LocalizedText("疯狂预言者", "Mad Prophet")
    public static let icon = "🔮"
    public static let description = LocalizedText(
        """
一个衣衫褴褛的老人蹲在路边，双眼蒙着布条，嘴里喃喃自语。

当你靠近时，他突然抬起头，布条下的眼眶空洞无物——但你感觉他正在“看”着你。

「我知道你的命运，」他沙哑地说，「想听听吗？」
""",
        """
An elderly man in rags squats by the roadside, blindfolded, muttering to himself.

When you approach, he lifts his head—empty sockets beneath the cloth—yet you feel his gaze.

"I know your fate," he rasps. "Do you wish to hear it?"
"""
    )
    
    public static func generate(context: EventContext, rng: inout SeededRNG) -> EventOffer {
        _ = context
        _ = rng
        
        let abyssalGaze = CardRegistry.require("abyssal_gaze").name
        let options: [EventOption] = [
            EventOption(
                title: LocalizedText("聆听预言", "Listen to the prophecy"),
                preview: LocalizedText(
                    "获得卡牌：\(abyssalGaze.zhHans)；疯狂 +4",
                    "Gain card: \(abyssalGaze.en); Madness +4"
                ),
                effects: [
                    .addCard(cardId: "abyssal_gaze"),
                    .applyStatus(statusId: "madness", stacks: 4),
                ]
            ),
            EventOption(
                title: LocalizedText("打断他", "Interrupt him"),
                preview: LocalizedText(
                    "进入战斗：疯狂预言者（精英）",
                    "Enter battle: Mad Prophet (Elite)"
                ),
                effects: [],
                followUp: .startEliteBattle(enemyId: "mad_prophet")
            ),
            EventOption(
                title: LocalizedText("给予金币安抚", "Offer gold to calm him"),
                preview: LocalizedText(
                    "失去 30 金币；回复 15 HP；疯狂 -2",
                    "Lose 30 gold; restore 15 HP; Madness -2"
                ),
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
