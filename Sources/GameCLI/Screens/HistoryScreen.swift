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
        ║                  📜 战斗历史记录                      ║
        ╚═══════════════════════════════════════════════════════╝
        \(Terminal.reset)
        """)
        
        if records.isEmpty {
            print("        \(Terminal.dim)暂无战斗记录\(Terminal.reset)")
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd HH:mm"
            
            print("        \(Terminal.dim)序号  时间         结果   回合  剩余HP  伤害输出\(Terminal.reset)")
            print("        \(Terminal.dim)────────────────────────────────────────────────\(Terminal.reset)")
            
            for (index, record) in records.reversed().enumerated() {
                let resultIcon = record.won ? "\(Terminal.green)✓ 胜利\(Terminal.reset)" : "\(Terminal.red)✗ 失败\(Terminal.reset)"
                let dateStr = dateFormatter.string(from: record.timestamp)
                let hpStr = "\(record.playerFinalHP)/\(record.playerMaxHP)".padding(toLength: 7, withPad: " ", startingAt: 0)
                let indexStr = String(format: "%2d", index + 1)
                let turnStr = String(format: "%3d", record.turnsPlayed)
                
                print("        \(indexStr)    \(dateStr)  \(resultIcon)  \(turnStr)   \(hpStr)  \(record.totalDamageDealt)")
            }
            
            print()
            print("        \(Terminal.dim)显示最近 \(records.count) 场战斗 (共 \(historyService.recordCount) 场)\(Terminal.reset)")
        }
        
        print()
        NavigationBar.render(items: [.back])
        NavigationBar.waitForBack()
    }
}

