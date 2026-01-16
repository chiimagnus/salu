import Foundation
import GameCore

/// 设置菜单界面
enum SettingsScreen {
    
    static func show(historyService: HistoryService, showLog: Bool, language: GameLanguage) {
        Terminal.clear()
        
        let recordCount = historyService.recordCount
        let logStatus = showLog
            ? "\(Terminal.green)\(L10n.text("开启", "On"))\(Terminal.bold)\(Terminal.yellow)"
            : "\(Terminal.dim)\(L10n.text("关闭", "Off"))\(Terminal.bold)\(Terminal.yellow)"
        let languageName = L10n.text(language.displayName, language.displayName)
        
        print("""
        \(Terminal.bold)\(Terminal.yellow)
        ╔═══════════════════════════════════════════════════════╗
        ║                    ⚙️  \(L10n.text("设置菜单", "Settings"))                       ║
        ╠═══════════════════════════════════════════════════════╣
        ║                                                       ║
        ║  \(Terminal.reset)\(Terminal.cyan)[1]\(Terminal.bold)\(Terminal.yellow) 📜 \(L10n.text("查看历史记录", "View History"))                            ║
        ║  \(Terminal.reset)\(Terminal.cyan)[2]\(Terminal.bold)\(Terminal.yellow) 📊 \(L10n.text("查看战绩统计", "View Statistics"))                           ║
        ║  \(Terminal.reset)\(Terminal.red)[3]\(Terminal.bold)\(Terminal.yellow) 🗑️  \(L10n.text("清除历史记录", "Clear History")) \(Terminal.dim)(\(recordCount) \(L10n.text("条", "records")))\(Terminal.bold)\(Terminal.yellow)                   ║
        ║  \(Terminal.reset)\(Terminal.cyan)[4]\(Terminal.bold)\(Terminal.yellow) 📦 \(L10n.text("资源管理（池子/注册表）", "Resource Browser"))                  ║
        ║  \(Terminal.reset)\(Terminal.cyan)[5]\(Terminal.bold)\(Terminal.yellow) 📖 \(L10n.text("游戏帮助", "Help"))                                ║
        ║  \(Terminal.reset)\(Terminal.cyan)[6]\(Terminal.bold)\(Terminal.yellow) 📋 \(L10n.text("日志显示", "Show Log")) [\(logStatus)]                       ║
        ║  \(Terminal.reset)\(Terminal.cyan)[7]\(Terminal.bold)\(Terminal.yellow) 🗂️ \(L10n.text("数据目录", "Data Directory"))（SALU_DATA_DIR）                  ║
        ║  \(Terminal.reset)\(Terminal.cyan)[8]\(Terminal.bold)\(Terminal.yellow) 🧭 \(L10n.text("事件种子工具", "Event Seed Tool"))（\(L10n.text("开发者", "Dev"))）                     ║
        ║  \(Terminal.reset)\(Terminal.cyan)[9]\(Terminal.bold)\(Terminal.yellow) 🌐 \(L10n.text("语言", "Language"))：\(languageName)                           ║
        ║                                                       ║
        ╠═══════════════════════════════════════════════════════╣
        ║  \(Terminal.reset)\(Terminal.dim)[q] \(L10n.text("返回主菜单", "Back to Main Menu"))\(Terminal.bold)\(Terminal.yellow)                                 ║
        ╚═══════════════════════════════════════════════════════╝
        \(Terminal.reset)
        """)
        
        print("\(Terminal.yellow)\(L10n.text("请选择", "Select")) > \(Terminal.reset)", terminator: "")
    }
}
