import Foundation
import GameCore

/// 帮助界面
enum HelpScreen {
    
    /// 显示帮助界面
    /// - Parameter fromBattle: 是否从战斗界面调用（影响导航栏显示）
    static func show(fromBattle: Bool = false) {
        Terminal.clear()
        print("""
        \(Terminal.bold)\(Terminal.cyan)
        ╔═══════════════════════════════════════════════════════╗
        ║                     📖 \(L10n.text("游戏帮助", "Help"))                       ║
        ╠═══════════════════════════════════════════════════════╣
        ║                                                       ║
        ║  \(Terminal.yellow)\(L10n.text("战斗操作", "Battle Controls"))\(Terminal.cyan)                                          ║
        ║  ────────                                             ║
        ║  \(Terminal.reset)N\(Terminal.cyan)      \(L10n.text("打出第 N 张手牌（不需目标/单敌人）", "Play card N (no target/single enemy)"))        ║
        ║  \(Terminal.reset)N M\(Terminal.cyan)    \(L10n.text("打出第 N 张手牌，目标为第 M 个敌人", "Play card N targeting enemy M"))         ║
        ║  \(Terminal.reset)0\(Terminal.cyan)      \(L10n.text("结束当前回合", "End turn"))                              ║
        ║  \(Terminal.reset)q\(Terminal.cyan)      \(L10n.text("返回主菜单（保留存档）", "Back to menu (keep save)"))                    ║
        ║                                                       ║
        ║  \(Terminal.yellow)\(L10n.text("地图操作", "Map Controls"))\(Terminal.cyan)                                          ║
        ║  ────────                                             ║
        ║  \(Terminal.reset)1-N\(Terminal.cyan)    \(L10n.text("选择下一个节点", "Choose next node"))                            ║
        ║  \(Terminal.reset)abandon\(Terminal.cyan) \(L10n.text("放弃当前冒险", "Abandon current run"))                              ║
        ║                                                       ║
        ║  \(Terminal.yellow)\(L10n.text("游戏规则", "Rules"))\(Terminal.cyan)                                          ║
        ║  ────────                                             ║
        ║  \(Terminal.reset)• \(L10n.text("每回合开始时获得 3 点能量", "Gain 3 energy at the start of each turn"))\(Terminal.cyan)                       ║
        ║  \(Terminal.reset)• \(L10n.text("每回合抽 5 张牌", "Draw 5 cards each turn"))\(Terminal.cyan)                                 ║
        ║  \(Terminal.reset)• \(L10n.text("格挡在每回合开始时清零", "Block resets at the start of each turn"))\(Terminal.cyan)                          ║
        ║  \(Terminal.reset)• \(L10n.text("伤害会先被格挡吸收", "Damage is absorbed by Block first"))\(Terminal.cyan)                              ║
        ║  \(Terminal.reset)• \(L10n.text("将敌人 HP 降为 0 即可获胜", "Reduce enemy HP to 0 to win"))\(Terminal.cyan)                       ║
        ║  \(Terminal.reset)• \(L10n.text("日志显示可在设置菜单中开关", "Log display can be toggled in Settings"))\(Terminal.cyan)                      ║
        ║                                                       ║
        ╚═══════════════════════════════════════════════════════╝
        \(Terminal.reset)
        """)

        // 占卜家序列机制说明（P1/P0）
        print("""

        \(Terminal.bold)🔮 \(L10n.text("占卜家序列机制（v1.0）", "Seer Mechanics (v1.0)"))\(Terminal.reset)
        - \(Terminal.magenta)👁️ \(L10n.text("预知 N", "Foresee N"))\(Terminal.reset)：\(L10n.text("查看抽牌堆顶 N 张牌，选择 1 张入手，其余按原顺序放回。", "Look at the top N cards of your draw pile, choose 1 to add to hand, return the rest in order.")) 
          \(Terminal.dim)\(L10n.text("在 CLI 中会弹出“预知选牌”界面，输入 1..N 选择。", "The CLI will prompt a Foresee selection; enter 1..N to choose."))\(Terminal.reset)
        - \(Terminal.cyan)⏪ \(L10n.text("回溯 N", "Rewind N"))\(Terminal.reset)：\(L10n.text("从弃牌堆顶部（最近弃置/打出的牌）取回 N 张到手牌。", "Return the top N cards from your discard pile to your hand.")) 
        - \(Terminal.blue)🌀 \(L10n.text("疯狂", "Madness"))\(Terminal.reset)：\(L10n.text("占卜家核心代价，回合结束时 -1。", "Core cost of the Seer; decreases by 1 at turn end.")) 
          \(Terminal.dim)\(L10n.text("达到阈值会触发负面效果（如 ≥3/≥6/≥10）；可用冥想/净化仪式/净化符文清理。", "Thresholds trigger negative effects (≥3/≥6/≥10); clear with Meditation/Purification Ritual/Purification Rune."))\(Terminal.reset)
        """)

        // 数据目录（P0.1：帮助里也需要可见）
        let (dir, source) = DataDirectory.resolved()
        let sourceText: String
        switch source {
        case .envOverride:
            sourceText = "SALU_DATA_DIR"
        case .platformDefault:
            sourceText = L10n.text("平台默认目录", "Platform default directory")
        case .temporaryFallback:
            sourceText = L10n.text("系统临时目录回退", "System temp fallback")
        }
        print("""

        \(Terminal.bold)🗂️ \(L10n.text("数据目录（存档/设置/日志）", "Data Directory (saves/settings/logs)"))\(Terminal.reset)
        - \(L10n.text("路径", "Path"))：\(Terminal.yellow)\(dir.path)\(Terminal.reset)
        - \(L10n.text("来源", "Source"))：\(Terminal.dim)\(sourceText)\(Terminal.reset)
        - \(L10n.text("提示：也可在设置菜单 [7] 查看数据目录详情", "Tip: you can also view it in Settings [7]")) 
        """)
        NavigationBar.render(items: [fromBattle ? .backToGame : .back])
    }
}
