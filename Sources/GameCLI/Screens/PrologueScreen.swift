import GameCore

/// 序章界面
/// 在冒险开始时显示开场剧情
public struct PrologueScreen {
    
    /// 根据楼层显示对应的开场剧情
    /// - Parameter floor: 当前楼层（Act）
    public static func show(floor: Int) {
        Terminal.clear()
        
        let text = getPrologue(floor: floor)
        
        // 显示边框
        print("""
        \(Terminal.bold)\(Terminal.cyan)
        ╔═══════════════════════════════════════════════════════════════════╗
        ║                                                                   ║
        \(Terminal.reset)
        """)
        
        // 逐行显示文本（带格式）
        let lines = L10n.resolve(text).split(separator: "\n", omittingEmptySubsequences: false)
        for line in lines {
            let lineStr = String(line)
            // 判断是否为章节标题行
            if lineStr.contains("——") && lineStr.contains("章") {
                print("\(Terminal.bold)\(Terminal.yellow)  \(lineStr)\(Terminal.reset)")
            } else if lineStr.hasPrefix("「") || lineStr.hasPrefix("『") {
                // 对话高亮（使用绿色）
                print("\(Terminal.bold)\(Terminal.green)  \(lineStr)\(Terminal.reset)")
            } else {
                print("\(Terminal.dim)  \(lineStr)\(Terminal.reset)")
            }
        }
        
        print("""
        \(Terminal.bold)\(Terminal.cyan)
        ║                                                                   ║
        ╚═══════════════════════════════════════════════════════════════════╝
        \(Terminal.reset)
        """)
        
        // 等待用户按键继续
        NavigationBar.render(items: [.continueNext])
        NavigationBar.waitForBack()
    }
    
    /// 获取对应楼层的开场剧情
    private static func getPrologue(floor: Int) -> LocalizedText {
        switch floor {
        case 1:
            return chapter1Prologue
        case 2:
            return chapter2Prologue
        case 3:
            return chapter3Prologue
        default:
            return LocalizedText(
                """
                你踏入了未知的领域……
                
                ——第\(floor)章——
                """,
                """
                You step into the unknown...
                
                — Chapter \(floor) —
                """
            )
        }
    }
    
    /// 第一章开场：雨夜觉醒
    private static let chapter1Prologue = LocalizedText(
        """
        ——第一章：觉醒——
        
        雨夜。
        
        安德在暴雨中醒来，记忆一片空白。
        
        身旁站着一个面目模糊的神秘人，低语着关于「序列」与「终结」的话语。
        
        神秘人将一张灼热的卡牌塞入安德掌心，随即消失在雨幕中。
        
        安德感到手心传来的热度正在改变自己——
        他能感知到周围蠢蠢欲动的黑暗。
        
        第一只怪物从阴影中扑来。
        
        战斗，开始了。
        """,
        """
        — Chapter I: Awakening —
        
        A rainy night.
        
        Ander awakens in the downpour, memories erased.
        
        A mysterious figure with a blurred face stands nearby, whispering of the "Sequence" and "Ending."
        
        The stranger presses a searing card into Ander's palm and vanishes into the rain.
        
        Ander feels the heat in his hand changing him—
        he can sense the restless darkness around him.
        
        The first monster lunges from the shadows.
        
        The battle begins.
        """
    )
    
    /// 第二章开场：深入污染源（时钟塔）
    private static let chapter2Prologue = LocalizedText(
        """
        ——第二章：真相——
        
        第一个污染源已被净化，但安德心中的疑惑越来越深。
        
        海因斯说这只是开始。
        赛弗说上一个终结者已死。
        
        「你以为自己在拯救世界？」
        
        赛弗的警告在安德脑海中回响。
        
        第二个污染源位于一座古老的时钟塔。
        据说那里的时间流动异常——
        过去与未来在这里交织。
        
        安德发现这里的污染与第一处不同——
        他能看到过去的幻影在走廊中游荡。
        更令人不安的是，他在幻影中看到了自己的身影——
        但那个「自己」穿着不同的衣服，眼神中充满绝望。
        
        时钟塔的大门缓缓打开……
        """,
        """
        — Chapter II: Truth —
        
        The first source of corruption has been purified, yet Ander's doubts deepen.
        
        Hines says this is only the beginning.
        Cipher says the previous Ender is dead.
        
        "Do you truly believe you're saving the world?"
        
        Cipher's warning echoes in Ander's mind.
        
        The second source lies within an ancient clock tower.
        They say time flows strangely there—
        past and future intertwined.
        
        Ander finds the corruption here unlike the first—
        he sees phantoms of the past wandering the halls.
        More unsettling still, he sees himself among the phantoms—
        but that "self" wears different clothes, eyes full of despair.
        
        The clock tower's doors slowly open...
        """
    )
    
    /// 第三章开场：前往虚无之心
    private static let chapter3Prologue = LocalizedText(
        """
        ——最终章：终结——
        
        赛弗的真相揭示后，安德做出了决定。
        
        他要独自前往序列始祖的沉睡之地——「虚无之心」，
        一个存在于现实与梦境交界处的空间。
        
        海因斯试图阻止他：
        「你一个人去是送死！」
        
        安德回答：
        「你们已经牺牲了 46 个人。
        这一次，让我来终结这个循环——
        不是作为你们的棋子，而是作为我自己。」
        
        尼古拉拖着受伤的身体站起来：
        「我没法跟你去，但你要活着回来，听到了吗？」
        
        阿尔托第一次主动握住了安德的手：
        「……我会照顾好他们。」
        
        艾拉紧紧抱住了安德，像是要把他刻进自己的生命里。
        分开时，她将一枚旧怀表塞入安德手中，眼眶泛红：
        「这是你小时候送我的定情信物。
        带着它，带着我的心，活着回来。」
        
        她踮起脚尖，在安德唇上留下一个轻吻。
        
        安德踏入了通往虚无之心的传送门。
        没有回头。
        
        这是最后的战斗。
        """,
        """
        — Final Chapter: End —
        
        After Cipher's truth is revealed, Ander makes his decision.
        
        He will go alone to the resting place of the Sequence Progenitor—"The Heart of Nothingness,"
        a space that lies between reality and dreams.
        
        Hines tries to stop him:
        "Going alone is suicide!"
        
        Ander replies:
        "You've already sacrificed forty-six people.
        This time, I'll end the cycle—
        not as your pawn, but as myself."
        
        Nikola stands, wounded:
        "I can't go with you, but you must come back alive. Do you hear me?"
        
        For the first time, Alto grasps Ander's hand:
        "...I'll look after them."
        
        Aira embraces Ander tightly, as if engraving him into her life.
        When they part, she presses an old pocket watch into his hand, eyes red:
        "This was the keepsake you gave me as a child.
        Take it—and my heart—and come back alive."
        
        She rises on her toes, leaving a soft kiss on Ander's lips.
        
        Ander steps through the portal to the Heart of Nothingness.
        He does not look back.
        
        This is the final battle.
        """
    )
}
