import Foundation
import GameCore

/// 设置菜单界面
enum SettingsScreen {
    
    static func show(historyService: HistoryService) {
        Terminal.clear()
        
        let recordCount = historyService.recordCount
        
        print("""
        \(Terminal.bold)\(Terminal.yellow)
        ╔═══════════════════════════════════════════════════════╗
        ║                    ⚙️  设置菜单                       ║
        ╠═══════════════════════════════════════════════════════╣
        ║                                                       ║
        ║  \(Terminal.reset)\(Terminal.cyan)[1]\(Terminal.bold)\(Terminal.yellow) 📜 查看历史记录                            ║
        ║  \(Terminal.reset)\(Terminal.cyan)[2]\(Terminal.bold)\(Terminal.yellow) 📊 查看战绩统计                            ║
        ║  \(Terminal.reset)\(Terminal.red)[3]\(Terminal.bold)\(Terminal.yellow) 🗑️  清除历史记录 \(Terminal.dim)(\(recordCount) 条)\(Terminal.bold)\(Terminal.yellow)                   ║
        ║  \(Terminal.reset)\(Terminal.cyan)[4]\(Terminal.bold)\(Terminal.yellow) 📦 资源管理（池子/注册表）                  ║
        ║                                                       ║
        ╠═══════════════════════════════════════════════════════╣
        ║  \(Terminal.reset)\(Terminal.dim)[0] 返回主菜单\(Terminal.bold)\(Terminal.yellow)                                 ║
        ╚═══════════════════════════════════════════════════════╝
        \(Terminal.reset)
        """)
        
        print("\(Terminal.yellow)请选择 > \(Terminal.reset)", terminator: "")
    }
}

