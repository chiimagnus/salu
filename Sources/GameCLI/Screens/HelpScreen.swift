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
        ║                     📖 游戏帮助                       ║
        ╠═══════════════════════════════════════════════════════╣
        ║                                                       ║
        ║  \(Terminal.yellow)战斗操作\(Terminal.cyan)                                          ║
        ║  ────────                                             ║
        ║  \(Terminal.reset)N\(Terminal.cyan)      打出第 N 张手牌（不需目标/单敌人）        ║
        ║  \(Terminal.reset)N M\(Terminal.cyan)    打出第 N 张手牌，目标为第 M 个敌人         ║
        ║  \(Terminal.reset)0\(Terminal.cyan)      结束当前回合                              ║
        ║  \(Terminal.reset)q\(Terminal.cyan)      返回主菜单（保留存档）                    ║
        ║                                                       ║
        ║  \(Terminal.yellow)地图操作\(Terminal.cyan)                                          ║
        ║  ────────                                             ║
        ║  \(Terminal.reset)1-N\(Terminal.cyan)    选择下一个节点                            ║
        ║  \(Terminal.reset)abandon\(Terminal.cyan) 放弃当前冒险                              ║
        ║                                                       ║
        ║  \(Terminal.yellow)游戏规则\(Terminal.cyan)                                          ║
        ║  ────────                                             ║
        ║  \(Terminal.reset)• 每回合开始时获得 3 点能量\(Terminal.cyan)                       ║
        ║  \(Terminal.reset)• 每回合抽 5 张牌\(Terminal.cyan)                                 ║
        ║  \(Terminal.reset)• 格挡在每回合开始时清零\(Terminal.cyan)                          ║
        ║  \(Terminal.reset)• 伤害会先被格挡吸收\(Terminal.cyan)                              ║
        ║  \(Terminal.reset)• 将敌人 HP 降为 0 即可获胜\(Terminal.cyan)                       ║
        ║  \(Terminal.reset)• 日志显示可在设置菜单中开关\(Terminal.cyan)                      ║
        ║                                                       ║
        ╚═══════════════════════════════════════════════════════╝
        \(Terminal.reset)
        """)

        // 占卜家序列机制说明（P1/P0）
        print("""

        \(Terminal.bold)🔮 占卜家序列机制（v1.0）\(Terminal.reset)
        - \(Terminal.magenta)👁️ 预知 N\(Terminal.reset)：查看抽牌堆顶 N 张牌，选择 1 张入手，其余按原顺序放回。
          \(Terminal.dim)在 CLI 中会弹出“预知选牌”界面，输入 1..N 选择。\(Terminal.reset)
        - \(Terminal.cyan)⏪ 回溯 N\(Terminal.reset)：从弃牌堆顶部（最近弃置/打出的牌）取回 N 张到手牌。
        - \(Terminal.blue)🌀 疯狂\(Terminal.reset)：占卜家核心代价，回合结束时 -1。
          \(Terminal.dim)达到阈值会触发负面效果（如 ≥3/≥6/≥10）；可用冥想/净化仪式/净化符文清理。\(Terminal.reset)
        """)

        // 数据目录（P0.1：帮助里也需要可见）
        let (dir, source) = DataDirectory.resolved()
        let sourceText: String
        switch source {
        case .envOverride:
            sourceText = "SALU_DATA_DIR"
        case .platformDefault:
            sourceText = "平台默认目录"
        case .temporaryFallback:
            sourceText = "系统临时目录回退"
        }
        print("""

        \(Terminal.bold)🗂️ 数据目录（存档/设置/日志）\(Terminal.reset)
        - 路径：\(Terminal.yellow)\(dir.path)\(Terminal.reset)
        - 来源：\(Terminal.dim)\(sourceText)\(Terminal.reset)
        - 提示：也可在设置菜单 \(Terminal.cyan)[7]\(Terminal.reset) 查看数据目录详情
        """)
        NavigationBar.render(items: [fromBattle ? .backToGame : .back])
    }
}

