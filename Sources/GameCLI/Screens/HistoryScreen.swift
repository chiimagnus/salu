import Foundation
import GameCore

/// 历史记录界面
enum HistoryScreen {
    
    static func show(historyService: HistoryService) {
        Terminal.clear()
        
        let records = historyService.getRecentRecords(10)
        
        print("""
        \(Terminal.bold)\(Terminal.cyan)
        ╔═══════════════════════════════════════════════════════╗
        ║                  📜 \(L10n.text("战斗历史记录", "Battle History"))                      ║
        ╚═══════════════════════════════════════════════════════╝
        \(Terminal.reset)
        """)
        
        if records.isEmpty {
            print("        \(Terminal.dim)\(L10n.text("暂无战斗记录", "No battle records"))\(Terminal.reset)")
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd HH:mm"
            
            print("        \(Terminal.dim)\(L10n.text("序号", "#"))  \(L10n.text("时间", "Time"))         \(L10n.text("结果", "Result"))   \(L10n.text("回合", "Turn"))  \(L10n.text("剩余HP", "HP Left"))  \(L10n.text("伤害输出", "Damage"))\(Terminal.reset)")
            print("        \(Terminal.dim)────────────────────────────────────────────────\(Terminal.reset)")
            
            for (index, record) in records.reversed().enumerated() {
                let resultIcon = record.won ? "\(Terminal.green)✓ \(L10n.text("胜利", "Win"))\(Terminal.reset)" : "\(Terminal.red)✗ \(L10n.text("失败", "Loss"))\(Terminal.reset)"
                let dateStr = dateFormatter.string(from: record.timestamp)
                let hpStr = "\(record.playerFinalHP)/\(record.playerMaxHP)".padding(toLength: 7, withPad: " ", startingAt: 0)
                let indexStr = String(format: "%2d", index + 1)
                let turnStr = String(format: "%3d", record.turnsPlayed)
                
                print("        \(indexStr)    \(dateStr)  \(resultIcon)  \(turnStr)   \(hpStr)  \(record.totalDamageDealt)")
            }
            
            print()
            print("        \(Terminal.dim)\(L10n.text("显示最近", "Showing last")) \(records.count) \(L10n.text("场战斗", "battles")) (\(L10n.text("共", "total")) \(historyService.recordCount))\(Terminal.reset)")
        }
        
        print()
        NavigationBar.render(items: [.back])
        NavigationBar.waitForBack()
    }
}
