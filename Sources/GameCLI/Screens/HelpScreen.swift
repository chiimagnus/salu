import Foundation
import GameCore

/// 帮助界面
enum HelpScreen {
    
    static func show() {
        Terminal.clear()
        print("""
        \(Terminal.bold)\(Terminal.cyan)
        ╔═══════════════════════════════════════════════════════╗
        ║                     📖 游戏帮助                       ║
        ╠═══════════════════════════════════════════════════════╣
        ║                                                       ║
        ║  \(Terminal.yellow)操作说明\(Terminal.cyan)                                          ║
        ║  ────────                                             ║
        ║  \(Terminal.reset)N\(Terminal.cyan)      打出第 N 张手牌（不需目标/单敌人）        ║
        ║  \(Terminal.reset)N M\(Terminal.cyan)    打出第 N 张手牌，目标为第 M 个敌人         ║
        ║  \(Terminal.reset)0\(Terminal.cyan)      结束当前回合                              ║
        ║  \(Terminal.reset)h\(Terminal.cyan)      显示此帮助信息                            ║
        ║  \(Terminal.reset)l\(Terminal.cyan)      展开/折叠事件日志                         ║
        ║  \(Terminal.reset)q\(Terminal.cyan)      返回主菜单                                ║
        ║                                                       ║
        ║  \(Terminal.yellow)游戏规则\(Terminal.cyan)                                          ║
        ║  ────────                                             ║
        ║  \(Terminal.reset)• 每回合开始时获得 3 点能量\(Terminal.cyan)                       ║
        ║  \(Terminal.reset)• 每回合抽 5 张牌\(Terminal.cyan)                                 ║
        ║  \(Terminal.reset)• 格挡在每回合开始时清零\(Terminal.cyan)                          ║
        ║  \(Terminal.reset)• 伤害会先被格挡吸收\(Terminal.cyan)                              ║
        ║  \(Terminal.reset)• 将敌人 HP 降为 0 即可获胜\(Terminal.cyan)                       ║
        ║                                                       ║
        ╚═══════════════════════════════════════════════════════╝
        \(Terminal.reset)
        """)
        NavigationBar.render(items: [.backToGame])
    }
}

