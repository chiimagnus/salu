import GameCore

/// 章节结束界面
/// 用于在 Boss 战胜利后显示章节收束/结局文本
public struct ChapterEndScreen {
    
    /// 显示章节结束文本
    /// - Parameters:
    ///   - floor: 当前楼层（Act）
    ///   - maxFloor: 最大楼层
    ///   - isVictory: 是否为最终胜利（通关）
    public static func show(floor: Int, maxFloor: Int, isVictory: Bool) {
        Terminal.clear()
        
        let text = ChapterText.getChapterEnding(floor: floor, maxFloor: maxFloor)
        
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
            if lineStr.contains("——") {
                print("\(Terminal.bold)\(Terminal.yellow)  \(lineStr)\(Terminal.reset)")
            } else if lineStr.contains("🔥") {
                print("\(Terminal.bold)\(Terminal.red)  \(lineStr)\(Terminal.reset)")
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
        if isVictory {
            print("\n\(Terminal.bold)\(Terminal.green)\(L10n.text("恭喜通关！", "Congratulations!"))\(Terminal.reset)")
            NavigationBar.render(items: [.backToMenu])
        } else {
            print("\n\(Terminal.dim)\(L10n.text("即将进入下一章…", "Proceeding to the next chapter..."))\(Terminal.reset)")
            NavigationBar.render(items: [.continueNext])
        }
        
        NavigationBar.waitForBack()
    }
}
