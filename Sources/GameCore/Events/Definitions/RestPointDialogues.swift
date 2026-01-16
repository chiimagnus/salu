// MARK: - Rest Point Dialogues (P5)
//
// v1.0 叙事风格：休息点作为"据点"，艾拉在这里等待安德归来
// 通过对话透露：
// - 艾拉与安德的关系（青梅竹马/恋人）
// - 童年回忆碎片
// - 对安德的担忧与支持

/// 休息点对话：艾拉的对话内容
/// 根据当前楼层（Act）返回不同的对话
public enum RestPointDialogues {
    
    /// 获取艾拉的对话（根据当前章节）
    /// - Parameter floor: 当前楼层（1=Act1, 2=Act2, 3=Act3）
    /// - Returns: 对话标题、对话内容、对话后的效果描述
    public static func getAiraDialogue(floor: Int) -> (title: LocalizedText, content: LocalizedText, effect: LocalizedText?) {
        switch floor {
        case 1:
            return (
                title: LocalizedText("与艾拉对话", "Talk with Aira"),
                content: LocalizedText(
                    """
                    艾拉看到你回来，露出了安心的微笑。
                    
                    "你回来了……"她轻声说道，"每次你离开，我都在担心。"
                    
                    她递给你一杯热茶：
                    "小时候你总说要成为英雄，保护所有人。我那时候觉得你在说傻话……"
                    
                    她的目光变得温柔：
                    "但现在我知道了。你一直都是认真的。"
                    
                    "无论发生什么，我都会在这里等你。"
                    """,
                    """
                    Aira smiles in relief when she sees you return.
                    
                    "You're back..." she says softly. "Every time you leave, I worry."
                    
                    She hands you a cup of hot tea:
                    "When we were kids, you always said you'd become a hero and protect everyone. I thought you were just being silly..."
                    
                    Her eyes soften:
                    "But now I know. You were always serious."
                    
                    "No matter what happens, I'll be waiting for you here."
                    """
                ),
                effect: nil
            )
        case 2:
            return (
                title: LocalizedText("与艾拉对话", "Talk with Aira"),
                content: LocalizedText(
                    """
                    艾拉紧紧抱住你，身体微微颤抖。
                    
                    "尼古拉告诉我了……你发现的那些真相。"她的声音有些哽咽。
                    
                    "我不在乎你是不是什么'终结者'，不在乎什么序列、什么使命。"
                    
                    她抬起头，眼眶泛红但目光坚定：
                    "我只在乎你能不能活着回来。"
                    
                    "答应我，无论如何都要活下去。"
                    """,
                    """
                    Aira hugs you tightly, her body trembling.
                    
                    "Nikola told me... about the truths you found." Her voice catches.
                    
                    "I don't care whether you're some 'Ender,' or about sequences or missions."
                    
                    She looks up, eyes red but resolute:
                    "I only care that you come back alive."
                    
                    "Promise me—no matter what, you'll survive."
                    """
                ),
                effect: nil
            )
        case 3:
            return (
                title: LocalizedText("与艾拉告别", "Farewell with Aira"),
                content: LocalizedText(
                    """
                    艾拉静静地看着你收拾行装，眼中满是不舍。
                    
                    "这次……是最后一次了吧。"她的声音很轻。
                    
                    你点了点头。
                    
                    她走过来，将一枚旧怀表塞入你的手心——那是你小时候送给她的定情信物。
                    
                    "带着它。"她踮起脚尖，在你唇上留下一个轻吻。
                    
                    "带着我的心，活着回来。"
                    """,
                    """
                    Aira watches quietly as you pack, eyes full of reluctance.
                    
                    "This time... it's the last, isn't it?" Her voice is barely a whisper.
                    
                    You nod.
                    
                    She steps forward and presses an old pocket watch into your palm—your childhood token of love.
                    
                    "Take it." She rises on her toes and leaves a soft kiss on your lips.
                    
                    "Carry my heart, and come back alive."
                    """
                ),
                effect: nil
            )
        default:
            return (
                title: LocalizedText("与艾拉对话", "Talk with Aira"),
                content: LocalizedText(
                    """
                    艾拉微笑着看着你。
                    
                    "累了就休息一下吧。"
                    
                    她的存在本身就是一种安慰。
                    """,
                    """
                    Aira smiles at you.
                    
                    "If you're tired, take a rest."
                    
                    Her presence alone is a comfort.
                    """
                ),
                effect: nil
            )
        }
    }
}
